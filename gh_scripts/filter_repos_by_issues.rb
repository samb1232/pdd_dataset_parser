require 'json'
require 'net/http'
require 'uri'
require 'set'

# Configuration
TOKEN = "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"
INPUT_FILE = "repositories_gh_2023.json"
OUTPUT_FILE = "selected_projects_2023_2025.json"
CACHE_FILE = "search_cache.json"
TARGET_COUNT = 600
MIN_ISSUES = 30
MAX_ISSUES = 1000
DATE_RANGE = "2023-01-01..2025-12-31"

def get_issue_count(full_name)
  query = "repo:#{full_name} is:issue is:closed closed:#{DATE_RANGE}"
  uri = URI("https://api.github.com/search/issues")
  params = { q: query, per_page: 1 }
  uri.query = URI.encode_www_form(params)

  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{TOKEN}"
  req['Accept'] = "application/vnd.github.v3+json"

  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }

  if res.code == "200"
    data = JSON.parse(res.body)
    return [data['total_count'], nil]
  elsif res.code == "403" && res['X-RateLimit-Remaining'] == "0"
    wait_time = (res['X-RateLimit-Reset'].to_i - Time.now.to_i) + 5
    return [nil, wait_time]
  elsif res.code == "422" # Validation failed (e.g. repo deleted)
    return [0, nil]
  else
    puts "Error checking #{full_name}: #{res.code} #{res.body}"
    return [nil, nil]
  end
end

# Load data
repos_links = JSON.parse(File.read(INPUT_FILE))
cache = File.exist?(CACHE_FILE) ? JSON.parse(File.read(CACHE_FILE)) : {}
results = File.exist?(OUTPUT_FILE) ? JSON.parse(File.read(OUTPUT_FILE)) : []

# Function to extract "owner/repo" from link
def extract_full_name(link)
  link.gsub("https://github.com/", "").strip
end

puts "Checking repos for #{MIN_ISSUES}-#{MAX_ISSUES} closed issues in #{DATE_RANGE}..."
puts "#{results.size}/#{TARGET_COUNT} projects already found."

repos_links.each do |link|
  break if results.size >= TARGET_COUNT
  
  full_name = extract_full_name(link)
  next if cache.key?(full_name) # Skip if already checked and failed

  # If repo was already found and in results, skip checking
  next if results.any? { |r| r['name'] == full_name }

  puts "Checking #{full_name}..."
  count, wait_time = get_issue_count(full_name)

  if wait_time
    # Handle search rate limit (usually 30 requests/min for authenticated search)
    # Since we only get 30/min, maybe we should sleep longer?
    # but the reset header should tell us.
    puts "Rate limit hit. Waiting for #{wait_time} seconds..."
    sleep wait_time
    # Retry once
    count, wait_time = get_issue_count(full_name)
  end

  if count
    cache[full_name] = count
    if count >= MIN_ISSUES && count <= MAX_ISSUES
      puts "Found matching repo: #{full_name} (#{count} closed issues)"
      results << {
        name: full_name,
        url: link,
        closed_issues_count: count
      }
      # Save progress periodically
      File.write(OUTPUT_FILE, JSON.pretty_generate(results))
    end
    # Periodically save cache to avoid re-checking 
    File.write(CACHE_FILE, JSON.generate(cache)) if cache.size % 10 == 0
    
    # Throttle a bit to avoid hitting rate limit too often (30 reqs/min = 2s per req)
    sleep 2 
  end
end

puts "Finished. Total selected projects: #{results.size}"
File.write(OUTPUT_FILE, JSON.pretty_generate(results))
