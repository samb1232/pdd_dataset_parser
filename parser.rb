require "json"
require "date"


def read_json_string(json_str)
  return JSON.parse(json_str)
end

def write_json_array_to_file(json_array, file_path)
  File.open(file_path, 'w') do |file|
    file.write(JSON.pretty_generate(json_array))
  end
end

def compare_dates(date1, date2)
  datetime1 = DateTime.parse(date1)
  datetime2 = DateTime.parse(date2)

  if datetime1 > datetime2
    return 1
  elsif datetime1 < datetime2
    return -1
  else
    return 0
  end
end

def filter_puzzles_with_comments(puzzles)
  puzzles.select { |puzzle| puzzle.key?("comments") }
end

def extract_project_link(issue_link)
  issue_link.split("/issues/")[0]
end

def group_puzzles_by_repository(puzzles)
  grouped_puzzles = {}
  puzzles.each do |puzzle|
    project_link = extract_project_link(puzzle["issueLink"])
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
      next unless puzzle["state"] == "closed"

      puzzles_arr = []
      pzl_close_date = puzzle["closed_at"]
      min_date_start = puzzle["created_at"]

      puzzles_group.each do |sub_puzzle|
        sub_pzl_create_date = sub_puzzle["created_at"]
        next if compare_dates(sub_pzl_create_date, pzl_close_date) != -1

        if sub_puzzle["state"] == "open"
          puzzles_arr << sub_puzzle
          min_date_start = sub_pzl_create_date if compare_dates(sub_pzl_create_date, min_date_start) == -1
        elsif compare_dates(sub_puzzle["closed_at"], pzl_close_date) != -1
          puzzles_arr << sub_puzzle
          min_date_start = sub_puzzle["created_at"] if compare_dates(sub_puzzle["created_at"], min_date_start) == -1
        end
      end

      new_puzzles_set = {
        "project_name" => extract_project_link(puzzle["issueLink"]),
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

data = read_json_string(File.read("data.json"))

filtered_puzzles = filter_puzzles_with_comments(data)
grouped_by_repos = group_puzzles_by_repository(filtered_puzzles)
grouped_by_timestamps = group_puzzles_by_timestamps(grouped_by_repos)

write_json_array_to_file(grouped_by_timestamps, "new_dataset2.json")
