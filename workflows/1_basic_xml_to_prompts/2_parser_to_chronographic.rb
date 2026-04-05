require "date"
require_relative "../utils/json_utils"
require_relative "../utils/date_utils"

def main
  input_file = "results/dataset_xml_by_timestamps.json"
  unless File.exist?(input_file)
    puts "Input file #{input_file} not found."
    return
  end

  puzzles_collections = load_json_file(input_file)
  
  refactored_collections = puzzles_collections.map do |collection|
    refactor_puzzles_collection(collection)
  end

  write_json_array_to_file(refactored_collections, "dataset_simple_chronographic.json")
  puts "Generated dataset_simple_chronographic.json"
end

def refactor_puzzles_collection(puzzles_collection)
  puzzles = puzzles_collection["puzzles"].map do |puzzle|
    {
      "id"         => puzzle["id"],
      "created_at" => parse_datetime(puzzle["created_at"]),
      "body"       => puzzle["body"],
      "file"       => puzzle["file"],
      "lines"      => puzzle["lines"]
    }
  end

  sorted_puzzles = puzzles.sort_by { |puzzle| puzzle["created_at"] }
  
  return {} if sorted_puzzles.empty?

  start_date = sorted_puzzles.first["created_at"]
  
  sorted_puzzles.each_with_index do |puzzle, index|
    # Update chosen_puzzle_id to the new index if it matches the original ID
    if puzzle["id"] == puzzles_collection["chosen_puzzle_id"]
      puzzles_collection["chosen_puzzle_id"] = index
    end
    
    puzzle["id"] = index
    puzzle["days_since_first_puzzle"] = (puzzle["created_at"] - start_date).to_i
  end

  {
    "project_name"     => puzzles_collection["project_name"],
    "puzzles_len"      => puzzles_collection["puzzles_len"],
    "chosen_puzzle_id" => puzzles_collection["chosen_puzzle_id"],
    "puzzles"          => sorted_puzzles
  }
end

main if __FILE__ == $0
