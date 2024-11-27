require "json"
require "date"

def read_json_file(filename)
  File.open(filename, "r") do |file|
    read_json_string(file.read)
  end
end

def read_json_string(json_str)
  return JSON.parse(json_str)
end

def write_json_array_to_file(json_array, file_path)
  json_string = JSON.pretty_generate(json_array)
  File.open(file_path, 'w') do |file|
    file.write(json_string)
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
  filtered_puzzles = []
  puzzles.each do |puzzle|
    if puzzle.has_key? "comments"
      filtered_puzzles << puzzle
    end
  end
  return filtered_puzzles
end

def extract_project_link(issue_link)
  issue_link.split("/issues/")[0]
end

def group_puzzles_by_repository(puzzles)
  grouped_puzzles = {}
  puzzles.each do |puzzle|
    project_link = extract_project_link(puzzle["issueLink"])
    if grouped_puzzles.has_key? project_link
      grouped_puzzles[project_link] << puzzle
    else
      grouped_puzzles[project_link] = [puzzle]
    end
  end
  return grouped_puzzles.values
end

def group_puzzles_by_timestamps(puzzles_grouped_by_repos)
  // TODO: fix bug with empty puzzles arrays in resulting dataset
  grouped_puzzles = []
  puzzles_grouped_by_repos.each do |puzzles_arr|
    puzzles_arr.each do |puzzle|
      if !puzzle["closed_at"].nil?
        puzzles_arr = []
        
        min_date_start = puzzle["created_at"]
        puzzles_arr.each do |sub_puzzle|
          
          if compare_dates(sub_puzzle["created_at"], puzzle["closed_at"]) == -1
            if sub_puzzle["closed_at"].nil? or compare_dates(sub_puzzle["closed_at"], puzzle["closed_at"]) != -1
              puzzles_arr << sub_puzzle
              if compare_dates(sub_puzzle["created_at"], min_date_start) == -1
                min_date_start = sub_puzzle["created_at"]
              end
            end
          end
        end
        
        new_puzzles_set = {
          "project_name": extract_project_link(puzzle["issueLink"]),
          "data_start": min_date_start,
          "data_end": puzzle["closed_at"],
          "chosen_puzzle_id": puzzle["id"],
          "puzzless": puzzles_arr
        }
        grouped_puzzles << new_puzzles_set
      end
    end
  end
  return grouped_puzzles
end

data = read_json_file("data.json")

filtered_puzzles = filter_puzzles_with_comments(data)
grouped_by_repos = group_puzzles_by_repository(filtered_puzzles)
grouped_by_timestamps = group_puzzles_by_timestamps(grouped_by_repos)

write_json_array_to_file(grouped_by_timestamps, "new_dataset.json")
