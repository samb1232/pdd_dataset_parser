require "date"
require_relative "../utils/json_utils"
require_relative "../utils/parser_utils"

def main
  input_file = "results/dataset_from_xml.json"
  unless File.exist?(input_file)
    puts "Input file #{input_file} not found. Ensure you have run parser_xml.rb and renamed/moved the output."
    return
  end

  data = load_json_file(input_file)

  grouped_by_repos = group_puzzles_by_repository(data)
  grouped_by_timestamps = group_puzzles_by_timestamps(grouped_by_repos)
  
  write_json_array_to_file(grouped_by_timestamps, "dataset_xml_by_timestamps.json")
  puts "Generated dataset_xml_by_timestamps.json"
end

main if __FILE__ == $0
