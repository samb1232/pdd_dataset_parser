require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'time'

# File paths
INPUT_FILE = File.join(__dir__, 'gh_scripts', '300_selected_projects.json')
OUTPUT_DIR = File.join(__dir__, 'res', 'general_gh_project_info')
CHECKPOINT_FILE = File.join(OUTPUT_DIR, '.checkpoint.json')

FileUtils.mkdir_p(OUTPUT_DIR)

unless File.exist?(INPUT_FILE)
  puts "Input file not found: #{INPUT_FILE}"
  exit 1
end

if !ENV['GITHUB_TOKEN'] || ENV['GITHUB_TOKEN'].empty?
  puts "ERROR: GITHUB_TOKEN environment variable is not set."
  puts "This script requires a token to avoid strict rate limits (5,000 requests/hr)."
  exit 1
end

def headers
  {
    "Accept" => "application/vnd.github.v3+json",
    "User-Agent" => "Ruby-Script",
    "Authorization" => "token #{ENV['GITHUB_TOKEN']}"
  }
end

def handle_rate_limit(response)
  remaining = response['X-RateLimit-Remaining'].to_i
  if remaining <= 10
    reset_time = Time.at(response['X-RateLimit-Reset'].to_i)
    sleep_time = (reset_time - Time.now).ceil + 5 # Add 5 seconds buffer
    if sleep_time > 0
      puts "\n--- RATE LIMIT APPROACHING ---"
      puts "Sleeping for #{sleep_time} seconds (until #{reset_time.strftime('%H:%M:%S')})..."
      sleep(sleep_time)
      puts "Resuming..."
    end
  end
end

def api_get(url)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  headers.each { |k, v| req[k] = v }

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  handle_rate_limit(res)

  if res.is_a?(Net::HTTPSuccess)
    [JSON.parse(res.body), res]
  else
    puts "API Error: #{url} - #{res.code} #{res.message}"
    [nil, res]
  end
end

def get_repo_details(owner, repo)
  data, _ = api_get("https://api.github.com/repos/#{owner}/#{repo}")
  data
end

def get_contributors_count(owner, repo)
  # Efficient way to get count using headers
  _, res = api_get("https://api.github.com/repos/#{owner}/#{repo}/contributors?per_page=1&anon=1")
  
  if res && res.is_a?(Net::HTTPSuccess)
    link_header = res['Link']
    if link_header && link_header =~ /<([^>]+)>;\s*rel="last"/
      last_link = $1
      uri_last = URI(last_link)
      params = URI.decode_www_form(uri_last.query || '').to_h
      return params['page'].to_i
    end
    
    begin
      body = JSON.parse(res.body)
      return body.length
    rescue JSON::ParserError
      return 0
    end
  end
  0
end

def get_issue_comments(owner, repo, issue_number)
  comments_data, _ = api_get("https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue_number}/comments?per_page=100")
  return [] unless comments_data

  comments_data.map do |c|
    {
      "author" => c.dig('user', 'login'),
      "created_at" => c['created_at'],
      "updated_at" => c['updated_at'],
      "body" => c['body'],
      "url" => c['html_url'],
      "id" => c['id']
    }
  end
end

def get_issue_events(owner, repo, issue_number)
  events_data, _ = api_get("https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue_number}/events?per_page=100")
  return [] unless events_data

  events_data.map do |e|
    {
      "id" => e['id'],
      "node_id" => e['node_id'],
      "url" => e['url'],
      "actor" => e['actor'] ? {
        "id" => e.dig('actor', 'id'),
        "url" => e.dig('actor', 'url'),
        "site_admin" => e.dig('actor', 'site_admin'),
        "type" => e.dig('actor', 'type'),
      } : nil,
      "event" => e['event'],
      "commit_id" => e['commit_id'],
      "commit_url" => e['commit_url'],
      "created_at" => e['created_at']
    }
  end
end

def fetch_issues(owner, repo)
  # Fetch all closed issues since 2023-01-01
  issues = []
  page = 1
  max_issues = 400
  
  # GitHub search API is better for this specific date filtering
  # search format: repo:owner/repo is:issue is:closed closed:2023-01-01..2024-12-31
  query = URI.encode_www_form_component("repo:#{owner}/#{repo} is:issue is:closed closed:2023-01-01..2024-12-31")
  
  loop do
    url = "https://api.github.com/search/issues?q=#{query}&sort=updated&order=desc&per_page=100&page=#{page}"
    data, _ = api_get(url)
    
    break unless data && data['items'] && !data['items'].empty?
    
    items = data['items']
    # Filter out PRs (search API includes them even with is:issue sometimes depending on the query context)
    items.reject! { |i| i.key?('pull_request') }
    
    items.each do |item|
      break if issues.length >= max_issues
      
      issue_number = item['number']
      
      # Fetch comments and events
      comments = get_issue_comments(owner, repo, issue_number)
      events = get_issue_events(owner, repo, issue_number)
      
      # Calculate stats
      created_at = Time.parse(item['created_at'])
      closed_at = Time.parse(item['closed_at'])
      diff_seconds = (closed_at - created_at).to_i
      
      issue_data = {
        "project_link" => "https://github.com/#{owner}/#{repo}",
        "issue_link" => item['html_url'],
        "id" => item['id'].to_s,
        "closed_at" => item['closed_at'],
        "created_at" => item['created_at'],
        "body" => item['body'],
        "labels" => item['labels'].map { |l| l['name'] },
        "assignees" => item['assignees'].map { |a| a['login'] },
        "title" => item['title'],
        "comments" => comments,
        "issue_events" => events,
        "flags" => {
          "is_pull_request" => false,
          "is_open" => item['state'] == 'open',
          "has_assignees" => !item['assignees'].empty?,
          "has_labels" => !item['labels'].empty?,
          "has_comments" => !comments.empty?
        },
        "comments_count" => comments.length,
        "issue_events_count" => events.length,
        "time_to_resolution_seconds" => diff_seconds,
        "time_to_resolution_days" => (diff_seconds / 86400.0).round(2)
      }
      
      issues << issue_data
    end
    
    break if items.length < 100 || issues.length >= max_issues
    page += 1
  end
  
  issues
end

# Main execution
projects = JSON.parse(File.read(INPUT_FILE))
puts "Found #{projects.length} projects in input."

checkpoint = if File.exist?(CHECKPOINT_FILE)
               JSON.parse(File.read(CHECKPOINT_FILE))
             else
               []
             end

projects.each_with_index do |project, idx|
  project_name = project['name']
  
  if checkpoint.include?(project_name)
    puts "[#{idx+1}/#{projects.length}] Skipping #{project_name} (already processed)"
    next
  end
  
  puts "[#{idx+1}/#{projects.length}] Processing #{project_name}..."
  
  parts = project_name.split('/')
  owner = parts[0]
  repo = parts[1]
  
  repo_details = get_repo_details(owner, repo)
  unless repo_details
    puts "Skipping #{project_name} due to missing repo details."
    next
  end
  
  contributors_count = get_contributors_count(owner, repo)
  puts "  Fetching issues..."
  issues = fetch_issues(owner, repo)
  
  # Calculate project-level stats
  first_issue_date = nil
  last_issue_date = nil
  
  issues.each do |issue|
    created_at = Time.parse(issue['created_at'])
    first_issue_date = created_at if first_issue_date.nil? || created_at < first_issue_date
    last_issue_date = created_at if last_issue_date.nil? || created_at > last_issue_date
  end
  
  result = {
    "project_link" => "https://github.com/#{owner}/#{repo}",
    "project_language" => repo_details['language'],
    "project_stars" => repo_details['stargazers_count'],
    "project_forks" => repo_details['forks_count'],
    "project_contributors_count" => contributors_count,
    "issues_count" => issues.length,
    "first_issue_date" => first_issue_date ? first_issue_date.iso8601 : nil,
    "last_issue_date" => last_issue_date ? last_issue_date.iso8601 : nil,
    "issues" => issues
  }
  
  # Save to file
  filename = "#{owner}-#{repo}.json".gsub('/', '-')
  File.write(File.join(OUTPUT_DIR, filename), JSON.pretty_generate(result))
  
  # Update checkpoint
  checkpoint << project_name
  File.write(CHECKPOINT_FILE, JSON.pretty_generate(checkpoint))
  
  puts "  Done #{project_name} - saved #{issues.length} issues."
end

puts "All projects processed."
