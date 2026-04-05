require 'json'
require 'net/http'
require 'uri'
require 'fileutils'

def headers
  h = {
    "Accept" => "application/vnd.github.v3+json",
    "User-Agent" => "Ruby-Script"
  }
  h["Authorization"] = "token #{ENV['GITHUB_TOKEN']}" if ENV['GITHUB_TOKEN'] && !ENV['GITHUB_TOKEN'].empty?
  h
end

def get_repo_details(owner, repo)
  uri = URI("https://api.github.com/repos/#{owner}/#{repo}")
  req = Net::HTTP::Get.new(uri)
  headers.each { |k, v| req[k] = v }
  
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  
  if res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)
    {
      'language' => data['language'],
      'stars' => data['stargazers_count'],
      'forks' => data['forks_count']
    }
  else
    puts "Failed to get repo details for #{owner}/#{repo}: #{res.code} #{res.message}"
    nil
  end
end

def get_contributors_count(owner, repo)
  uri = URI("https://api.github.com/repos/#{owner}/#{repo}/contributors?per_page=1&anon=1")
  req = Net::HTTP::Get.new(uri)
  headers.each { |k, v| req[k] = v }
  
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  
  if res.is_a?(Net::HTTPSuccess)
    link_header = res['Link']
    if link_header && link_header =~ /<([^>]+)>;\s*rel="last"/
      last_link = $1
      uri_last = URI(last_link)
      params = URI.decode_www_form(uri_last.query || '').to_h
      return params['page'].to_i
    end
    # No Link header, check body length
    begin
      body = JSON.parse(res.body)
      return body.length
    rescue JSON::ParserError
      return 0
    end
  else
    puts "Failed to get contributors for #{owner}/#{repo}: #{res.code} #{res.message}"
    0
  end
end

input_dir = File.join(__dir__, 'res', 'pdd_issues_split_by_project')
output_dir = File.join(__dir__, 'res', 'pdd_issues_split_enrich')

# Ensure output directory exists
FileUtils.mkdir_p(output_dir)

# Read all json files
json_files = Dir.glob(File.join(input_dir, '*.json'))
puts "Found #{json_files.length} json files to process."

if !ENV['GITHUB_TOKEN'] || ENV['GITHUB_TOKEN'].empty?
  puts "WARNING: GITHUB_TOKEN environment variable is not set. You might hit rate limits (60 requests/hr)."
end

json_files.each_with_index do |file, index|
  begin
    data = JSON.parse(File.read(file))
    
    project_url = data['project_link']
    unless project_url
      puts "[#{index+1}/#{json_files.length}] Skipping #{File.basename(file)}: No project_link"
      next
    end
    
    # "https://github.com/amihaiemil/comdor" -> ["amihaiemil", "comdor"]
    parts = project_url.sub(/\.git$/, '').split('/')
    owner = parts[-2]
    repo = parts[-1]
    
    puts "[#{index+1}/#{json_files.length}] Processing #{owner}/#{repo}..."
    
    details = get_repo_details(owner, repo)
    contributors_count = get_contributors_count(owner, repo)
    
    if details
      data['project_language'] = details['language']
      data['project_stars'] = details['stars']
      data['project_forks'] = details['forks']
    else
      data['project_language'] = nil
      data['project_stars'] = nil
      data['project_forks'] = nil
    end
    
    data['project_contributors_count'] = contributors_count
    
    out_file = File.join(output_dir, File.basename(file))
    File.write(out_file, JSON.pretty_generate(data))
    
    # Small sleep to be nice to the API
    sleep 0.5
  rescue => e
    puts "Error processing #{file}: #{e.message}"
  end
end

puts "Done!"
