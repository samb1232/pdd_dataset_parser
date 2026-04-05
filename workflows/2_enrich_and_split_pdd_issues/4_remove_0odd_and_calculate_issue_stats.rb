require 'json'
require 'time'
require 'fileutils'

input_dir = 'res/pdd_projects_with_issues'
if !Dir.exist?(input_dir)
  # fallback to checking relative to the file if run from the script directory
  input_dir = File.join(File.expand_path('../../..', __dir__ || File.dirname(__FILE__)), 'res', 'pdd_projects_with_issues')
end

if !Dir.exist?(input_dir)
  puts "Input directory not found."
  exit 1
end

output_dir = 'res/pdd_projects_without_0pdd_events'
FileUtils.mkdir_p(output_dir)

json_files = Dir.glob(File.join(input_dir, '*.json'))
puts "Found #{json_files.length} json files to process."

json_files.each_with_index do |file, index|
  begin
    data = JSON.parse(File.read(file))
    
    issues = data['issues'] || []
    
    # We will compute the min and max dates across all issues
    first_issue_date = nil
    last_issue_date = nil
    
    issues.each do |issue|
      # 1. Clean 0pdd comments and events
      if issue['comments'] && issue['comments'].is_a?(Array)
        issue['comments'].reject! { |c| c['author'] == '0pdd' }
      end

      if issue['issue_events'] && issue['issue_events'].is_a?(Array)
        issue['issue_events'].reject! do |e| 
          e.dig('actor', 'url') == 'https://api.github.com/users/0pdd'
        end
      end
      
      if issue['events'] && issue['events'].is_a?(Array)
        issue['events'].reject! do |e| 
          e.dig('actor', 'url') == 'https://api.github.com/users/0pdd'
        end
      end

      # 2. Calculate stats
      # Comments count
      issue['comments_count'] = (issue['comments'] || []).length
      
      # Issue events count
      issue['issue_events_count'] = (issue['issue_events'] || []).length
      
      # Time to resolution
      created_at_str = issue['created_at']
      closed_at_str = issue['closed_at']
      
      created_at = created_at_str ? Time.parse(created_at_str) : nil
      closed_at = closed_at_str ? Time.parse(closed_at_str) : nil
      
      if created_at && closed_at
        diff_seconds = (closed_at - created_at).to_i
        issue['time_to_resolution_days'] = (diff_seconds / 86400.0).round(2)
      else
        issue['time_to_resolution_days'] = nil
      end
      
      # Track global first/last project dates
      if created_at
        first_issue_date = created_at if first_issue_date.nil? || created_at < first_issue_date
        last_issue_date =  created_at if last_issue_date.nil?  || created_at > last_issue_date
      end
    end
    
    data['first_issue_date'] = first_issue_date ? first_issue_date.iso8601 : nil
    data['last_issue_date'] = last_issue_date ? last_issue_date.iso8601 : nil
    
    out_file = File.join(output_dir, File.basename(file))
    File.write(out_file, JSON.pretty_generate(data))
    
    puts "[#{index+1}/#{json_files.length}] Processed #{File.basename(file)}"
  rescue => e
    puts "Error processing #{file}: #{e.message}"
  end
end

puts "Done!"
