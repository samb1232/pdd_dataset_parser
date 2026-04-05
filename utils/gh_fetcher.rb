require "uri"
require "net/http"
require "json"

def fetch_issue_data(issue_url, github_token = nil)
  # Parse owner / repo / issue number from URL
  uri = URI(issue_url)
  path_parts = uri.path.split("/").reject(&:empty?)
  owner, repo, _, issue_number = path_parts
  return nil unless owner && repo && issue_number

  # Build GitHub API URLs
  base = "https://api.github.com"
  issue_api  = "#{base}/repos/#{owner}/#{repo}/issues/#{issue_number}"
  comments_api = "#{base}/repos/#{owner}/#{repo}/issues/#{issue_number}/comments"
  events_api = "#{base}/repos/#{owner}/#{repo}/issues/#{issue_number}/events"

  headers = {
    "Accept" => "application/vnd.github.v3+json",
    "User-Agent" => "Ruby Script"
  }
  headers["Authorization"] = "Bearer #{github_token}" if github_token

  # Helper to fetch JSON from a URL
  fetch_json = ->(url) do
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri, headers)
    res = http.request(req)
    res.code == "200" ? JSON.parse(res.body) : nil
  end

  issue  = fetch_json.call(issue_api)
  return nil unless issue

  labels   = (issue["labels"] || []).map { |l| l["name"] }
  assignees = (issue["assignees"] || []).map { |a| a["login"] }

  # FULL comments with more info
  comments = (fetch_json.call(comments_api) || []).map { |c|
    {
      "author" => c["user"]&.fetch("login", nil),
      "created_at" => c["created_at"],
      "updated_at" => c["updated_at"],
      "body" => c["body"],
      "url" => c["html_url"],
      "id" => c["id"]
    }
  }

  issue_events = fetch_json.call(events_api) || []

  flags = {
    "is_pull_request" => !issue["pull_request"].nil?,
    "is_open" => issue["state"] == "open",
    "has_assignees" => !assignees.empty?,
    "has_labels" => !labels.empty?,
    "has_comments" => !comments.empty?
  }

  {
    "issue_url" => issue["html_url"],
    "labels" => labels,
    "assignees" => assignees,
    "title" => issue["title"],
    "comments" => comments,
    "issue_events" => issue_events,
    "flags" => flags
  }.to_json
end
