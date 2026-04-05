require "json"
require_relative "../utils/gh_torrent.rb"
require_relative "../utils/json_utils"

CHECKPOINT_FILE = "enrich_tickets_checkpoint.json"
OUTPUT_FILE     = "enriched_tickets.json"

def load_checkpoint
  return { "index" => -1, "count" => 0 } unless File.exist?(CHECKPOINT_FILE)
  
  JSON.parse(File.read(CHECKPOINT_FILE))
end

def save_checkpoint(index, count)
  File.write(CHECKPOINT_FILE, JSON.dump({ "index" => index, "count" => count }))
end

def enrich_tickets(input_path, github_token = nil)
  tickets = load_json_file(input_path)
  total_tickets = tickets.length
  
  checkpoint = load_checkpoint
  start_index = checkpoint["index"] + 1
  processed_count = checkpoint["count"]

  results = []
  if File.exist?(OUTPUT_FILE) && start_index > 0
    results = load_json_file(OUTPUT_FILE)
  end

  puts "Resuming from index #{start_index}/#{total_tickets} (#{processed_count} already enriched)"

  tickets[start_index..-1].each_with_index do |ticket, i|
    current_index = start_index + i
    puts "Processing #{current_index + 1}/#{total_tickets} (#{processed_count + 1})..."

    next unless ticket["done"] == true

    issue_url = ticket["issue_link"]
    next if issue_url.nil? || issue_url.strip.empty?

    begin
      issue_json_str = fetch_issue_data(issue_url, github_token)
      github_metadata = JSON.parse(issue_json_str)

      enriched_ticket = ticket.merge("github" => github_metadata)
      results << enriched_ticket
      processed_count += 1

      write_json_array_to_file(results, OUTPUT_FILE)
      save_checkpoint(current_index, processed_count)
    rescue => e
      warn "Failed to fetch issue data for #{issue_url}: #{e.message}"
      next
    end
  end

  results
end

def main
  input_file = "res/puzzle_related_data_from_xml.json"
  unless File.exist?(input_file)
    puts "Input file #{input_file} not found. Ensure you have run parser_xml.rb and placed the output in res/ folder."
    return
  end

  enriched_data = enrich_tickets(input_file)
  puts "Done. Final count: #{enriched_data.length} enriched tickets."
end

main if __FILE__ == $0
