require "json"
require "date"
require_relative "../../utils/json_utils"
require_relative "../../utils/parser_utils"

def main
  input_file = "dataset.json"
  unless File.exist?(input_file)
    puts "Input file #{input_file} not found."
    return
  end

  data = load_json_file(input_file)
  filtered_puzzles = filter_puzzles_with_comments(data)
  
  grouped_by_repos = group_puzzles_by_repository(filtered_puzzles)
  grouped_by_timestamps = group_puzzles_by_timestamps(grouped_by_repos)
  
  cleared_puzzles = strip_unnecessary_fields(grouped_by_timestamps)

  write_json_array_to_file(cleared_puzzles, "dataset_group_by_repos.json")
  puts "Generated dataset_group_by_repos.json"
end

def filter_puzzles_with_comments(puzzles)
  puzzles.select { |puzzle| puzzle.key?("comments") }
end

def strip_unnecessary_fields(dataset)
  dataset.map do |puzzles_set|
    {
      'project_name' => puzzles_set['project_name'],
      'data_start' => puzzles_set['data_start'],
      'data_end' => puzzles_set['data_end'],
      'chosen_puzzle_id' => puzzles_set['chosen_puzzle_id'],
      'puzzles_len' => puzzles_set['puzzles_len'],
      'puzzles' => puzzles_set['puzzles'].map do |puzzle|
        {
          "id" => puzzle["id"],
          "referenced" => puzzle["referenced"],
          "mentioned" => puzzle["mentioned"],
          "time" => puzzle["time"],
          "lines" => puzzle["lines"],
          "ticketNo" => puzzle["ticketNo"],
          "issueLink" => puzzle["issueLink"],
          "title" => puzzle["title"]
        }
      end
    }
  end
end

main if __FILE__ == $0
