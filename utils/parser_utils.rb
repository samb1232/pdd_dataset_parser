require "date"
require_relative "project_utils"

def group_puzzles_by_repository(puzzles)
  puzzles.group_by { |puzzle| extract_project_link(puzzle["project_link"] || puzzle["issueLink"]) }.values
end

def group_puzzles_by_timestamps(puzzles_grouped_by_repos)
  grouped_puzzles = []
  puzzles_grouped_by_repos.each do |puzzles_group|
    puzzles_group.each do |puzzle|
      closed_at = puzzle["closed_at"]
      next if closed_at.nil?

      pzl_close_date = DateTime.parse(closed_at)
      puzzles_in_window = puzzles_group.select do |sub_puzzle|
        sub_create_date = DateTime.parse(sub_puzzle["created_at"])
        next false if sub_create_date > pzl_close_date

        if sub_puzzle["closed_at"]
          sub_close_date = DateTime.parse(sub_puzzle["closed_at"])
          next false if sub_close_date > pzl_close_date
        end
        true
      end

      next if puzzles_in_window.length <= 1

      min_date_start = puzzles_in_window.map { |p| DateTime.parse(p["created_at"]) }.min

      grouped_puzzles << {
        "project_name" => extract_project_link(puzzle["project_link"] || puzzle["issueLink"]),
        "data_start" => min_date_start,
        "data_end" => pzl_close_date,
        "chosen_puzzle_id" => puzzle["id"],
        "puzzles_len" => puzzles_in_window.length,
        "puzzles" => puzzles_in_window
      }
    end
  end
  grouped_puzzles
end
