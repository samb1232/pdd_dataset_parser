require "date"
require_relative "../utils/json_utils"



def group_puzzles_by_repository(puzzles)
  grouped_puzzles = {}
  puzzles.each do |puzzle|
    project_link = puzzle["project_link"]
    if grouped_puzzles.key?(project_link)
      grouped_puzzles[project_link] << puzzle
    else
      grouped_puzzles[project_link] = [puzzle]
    end
  end
  grouped_puzzles.values
end

def group_puzzles_by_timestamps(puzzles_grouped_by_repos)
  grouped_puzzles = []
  puzzles_grouped_by_repos.each do |puzzles_group|
    puzzles_group.each do |puzzle|
      next if puzzle["closed_at"].nil?
      
      puzzles_arr = []
      pzl_close_date = DateTime.parse(puzzle["closed_at"])
      min_date_start = DateTime.parse(puzzle["created_at"])

      puzzles_group.each do |sub_puzzle|
        sub_pzl_create_date = DateTime.parse(sub_puzzle["created_at"])
        next if sub_pzl_create_date > pzl_close_date

        if !sub_puzzle["closed_at"].nil?
          sub_pzl_close_date = DateTime.parse(sub_puzzle["closed_at"])
          next if sub_pzl_close_date > pzl_close_date
        end
        puzzles_arr << sub_puzzle
        if sub_pzl_create_date < min_date_start
          min_date_start = sub_pzl_create_date
        end
      end

      new_puzzles_set = {
        "project_name" => puzzle["project_link"],
        "data_start" => min_date_start,
        "data_end" => pzl_close_date,
        "chosen_puzzle_id" => puzzle["id"],
        "puzzles_len" => puzzles_arr.length,
        "puzzles" => puzzles_arr
      }
      grouped_puzzles << new_puzzles_set if new_puzzles_set["puzzles"].length > 1
    end
  end
  grouped_puzzles
end


def remove_unnecessary_fields(dataset)
  new_dataset = []
  dataset.each do |puzzles_set|
    new_puzzles_set = {}
    new_puzzles_set['project_name'] = puzzles_set['project_name']
    new_puzzles_set['data_start'] = puzzles_set['data_start']
    new_puzzles_set['data_end'] = puzzles_set['data_end']
    new_puzzles_set['chosen_puzzle_id'] = puzzles_set['chosen_puzzle_id']
    new_puzzles_set['puzzles_len'] = puzzles_set['puzzles_len']

    new_puzzles = [] 
    puzzles_set['puzzles'].each do |puzzle|
      new_puzzle = {
        "id": puzzle["id"],
        "referenced": puzzle["referenced"],
        "mentioned": puzzle["mentioned"],
        "time": puzzle["time"],
        "lines": puzzle["lines"],
        "ticketNo": puzzle["ticketNo"],
        "issueLink": puzzle["issueLink"],
        "title": puzzle["title"],
      }
      new_puzzles << new_puzzle
    end
    new_puzzles_set['puzzles'] = new_puzzles
    new_dataset << new_puzzles_set
  end
  new_dataset
end


data = json_string_to_hash_arr(File.read("results\\dataset_from_xml.json"))

grouped_by_repos = group_puzzles_by_repository(data)
grouped_by_timestamps = group_puzzles_by_timestamps(grouped_by_repos)

write_json_array_to_file(grouped_by_timestamps, "data_xml_by_timestamps.json")
