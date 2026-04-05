require 'zlib'
require 'json'
require 'set'

# Assuming execution from gh_scripts directory
SOURCE_DIR = "gharchive_2023"
RESULT_FILE = "repositories_gh_2023.json"

repos = Set.new

# Collect all .json.gz files in SOURCE_DIR
archives = Dir.glob(File.join(SOURCE_DIR, "*.json.gz"))

if archives.empty?
  puts "No archives found in #{SOURCE_DIR}."
  exit 1
end

archives.each do |file_path|
  puts "Processing #{File.basename(file_path)}..."
  
  begin
    Zlib::GzipReader.open(file_path) do |gz|
      gz.each_line do |line|
        begin
          # GH Archive files are JSON Lines format
          event = JSON.parse(line)
          
          # Check if the event is an IssuesEvent
          if event['type'] == 'IssuesEvent'
            # repo['name'] is in the format "owner/repo"
            repo_name = event.dig('repo', 'name')
            if repo_name
              repos.add("https://github.com/#{repo_name}")
            end
          end
        rescue JSON::ParserError
          # Some lines in GHArchive might be malformed or truncated
          next
        end
      end
    end
  rescue => e
    puts "Error processing #{file_path}: #{e.message}"
  end
end

total_count = repos.size
puts "Extraction complete. Found #{total_count} unique repositories."

# Save results as a JSON array of strings
begin
  File.write(RESULT_FILE, JSON.pretty_generate(repos.to_a))
  puts "Saved unique repository links to #{RESULT_FILE}"
rescue => e
  puts "Failed to write to #{RESULT_FILE}: #{e.message}"
end
