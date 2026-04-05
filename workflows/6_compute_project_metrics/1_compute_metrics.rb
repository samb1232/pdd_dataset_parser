require 'json'
require 'fileutils'

if ARGV.length < 2
  puts "Usage: ruby compute_metrics.rb <input_directory> <output_file.json>"
  exit 1
end

input_dir = ARGV[0]
output_file = ARGV[1]

unless Dir.exist?(input_dir)
  puts "Error: Input directory '#{input_dir}' does not exist."
  exit 1
end

results = []

Dir.glob(File.join(input_dir, "*.json")).each do |file_path|
  begin
    file_content = File.read(file_path)
    data = JSON.parse(file_content)
  rescue StandardError => e
    puts "Skipping #{file_path}: #{e.message}"
    next
  end

  project_link = data["project_link"] || file_path
  issues = data["issues"] || []
  total_issues = issues.length

  if total_issues == 0
    # Add minimal diagnostics and nulls for rates since denominator is 0
    results << {
      "project_link" => project_link,
      "issues_count" => data["issues_count"] || 0,
      "project_contributors_count" => data["project_contributors_count"],
      "first_issue_date" => data["first_issue_date"],
      "last_issue_date" => data["last_issue_date"],
      "issue_body_size_average" => nil,
      "mean_time_to_resolution_days" => nil,
      "average_comments_per_issue" => nil,
      "average_events_per_issue" => nil,
      "label_rate" => nil,
      "assignee_rate" => nil
    }
    next
  end

  # Metric Variables
  total_body_size = 0
  
  valid_ttr_sum = 0.0
  valid_ttr_count = 0
  
  total_comments = 0
  total_events = 0
  
  labeled_issues_count = 0
  assignee_issues_count = 0

  issues.each do |issue|
    # 1. issue_body_size_average
    body = issue["body"] || ""
    total_body_size += body.length

    # 2. mean_time_to_resolution_days
    ttr = issue["time_to_resolution_days"]
    if ttr.is_a?(Numeric)
      valid_ttr_sum += ttr
      valid_ttr_count += 1
    end

    # 3. average_comments_per_issue
    comments = issue["comments_count"]
    total_comments += comments.is_a?(Numeric) ? comments : 0

    # 4. average_events_per_issue
    events = issue["issue_events_count"]
    total_events += events.is_a?(Numeric) ? events : 0

    # 5. label_rate
    labels = issue["labels"] || []
    # Exclude "pdd" and "puzzle"
    valid_labels = labels.reject { |l| l.to_s.match?(/^(pdd|puzzle)$/i) }
    if valid_labels.length > 0
      labeled_issues_count += 1
    end

    # 6. assignee_rate
    has_assignees = false
    if issue["flags"] && (issue["flags"]["has_assignees"] == true || issue["flags"]["has_assignees"] == false)
      has_assignees = issue["flags"]["has_assignees"]
    elsif issue["assignees"] && issue["assignees"].is_a?(Array)
      has_assignees = issue["assignees"].length > 0
    end
    
    if has_assignees
      assignee_issues_count += 1
    end
  end

  repo_metrics = {
    "project_link" => project_link,
    "issues_count" => data["issues_count"],
    "project_contributors_count" => data["project_contributors_count"],
    "first_issue_date" => data["first_issue_date"],
    "last_issue_date" => data["last_issue_date"],
    
    "issue_body_size_average" => total_body_size.to_f / total_issues,
    "mean_time_to_resolution_days" => valid_ttr_count > 0 ? (valid_ttr_sum / valid_ttr_count) : nil,
    "average_comments_per_issue" => total_comments.to_f / total_issues,
    "average_events_per_issue" => total_events.to_f / total_issues,
    "label_rate" => labeled_issues_count.to_f / total_issues,
    "assignee_rate" => assignee_issues_count.to_f / total_issues
  }

  results << repo_metrics
end

# Write all combined results to output JSON
File.write(output_file, JSON.pretty_generate(results))
puts "Successfully processed #{results.length} repositories from '#{input_dir}'."
puts "Results written to '#{output_file}'."
