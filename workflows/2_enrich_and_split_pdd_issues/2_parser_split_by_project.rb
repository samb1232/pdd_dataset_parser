require "json"
require "fileutils"
require_relative "../../utils/json_utils"

def simplify_issue_events(issues)
  issues.map do |issue|
    next issue unless issue["issue_events"].is_a?(Array)

    issue["issue_events"] = issue["issue_events"].map do |event|
      actor = event["actor"]
      if actor.is_a?(Hash)
        event["actor"] = {
          "id" => actor["id"],
          "url" => actor["url"],
          "site_admin" => actor["site_admin"],
          "type" => actor["type"]
        }
      end

      # Remove redundant fields
      event.delete("performed_via_github_app")
      event
    end
    issue
  end
end

def flatten_github_metadata(issue)
  github_meta = issue.delete("github") || {}
  
  fields_to_flatten = %w[labels assignees title comments issue_events flags]
  fields_to_flatten.each do |field|
    issue[field] = github_meta[field] if github_meta.key?(field)
  end
  issue
end

def split_enriched_tickets_by_project(input_path)
  result_dir = "pdd_issues_split_by_project"
  FileUtils.mkdir_p(result_dir)

  unless File.exist?(input_path)
    puts "Input file #{input_path} not found."
    return
  end

  data = load_json_file(input_path)

  # Group by project_link
  projects = data.group_by do |item|
    project_link = item["project_link"].to_s
    raise "No project_link for item: #{item.inspect}" if project_link.empty?
    project_link
  end

  projects.each do |project_link, raw_issues|
    issues = raw_issues.map { |issue| flatten_github_metadata(issue.dup) }
    issues = simplify_issue_events(issues)

    # Filter projects with fewer than 8 issues
    next unless issues.length >= 8

    # Extract filename from project_link
    match = project_link.match(%r{github\.com/([^/]+)/(.+)$})
    filename = match ? "#{match[1]}-#{match[2]}.json" : "unknown-project.json"
    output_path = File.join(result_dir, filename)

    project_data = {
      "project_link" => project_link,
      "issues_count" => issues.length,
      "issues" => issues
    }

    write_json_array_to_file(project_data, output_path)
    puts "Wrote project #{project_link} (#{issues.length} issues) to #{output_path}"
  end
end

if __FILE__ == $0
  split_enriched_tickets_by_project("enriched_tickets.json")
end
