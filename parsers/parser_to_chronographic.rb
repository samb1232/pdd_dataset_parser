require "date"
require_relative "../utils/json_utils"


def main()
    puzzles_collections = json_string_to_hash_arr(File.read("results\\data_xml_by_timestamps_v2.json"))
    result = []
    puzzles_collections.each do |p_collection|
        p_collection_refactored = refactor_puzzles_collection(p_collection)
        result << p_collection_refactored
    end
    write_json_array_to_file(result, "data_simple_chronographic_12.json")
end


def refactor_puzzles_collection(puzzles_collection) 
    result = {
        "project_name" => puzzles_collection["project_name"],
        "puzzles_len" => puzzles_collection["puzzles_len"]
    }

    puzzles_without_extra_fields = get_puzzles_without_extra_fields(puzzles_collection["puzzles"])
    puzzles_sorted = puzzles_without_extra_fields.sort_by {|puzzle| puzzle["created_at"]}
    
    start_date = puzzles_sorted.first["created_at"].clone
    puzzles_sorted.each_with_index do |puzzle, index|
        if puzzle["id"] == puzzles_collection["chosen_puzzle_id"] then
            result["chosen_puzzle_id"] = i
        end
        
        puzzle["id"] = index
        puzzle["days_since_first_puzzle"] = (puzzle["created_at"] - start_date).to_i
    end

    result["puzzles"] = puzzles_sorted
    return result
end


def get_puzzles_without_extra_fields(puzzles)
    return puzzles.map do |puzzle|
        {
            "id" => puzzle["id"],
            "created_at" => DateTime.parse(puzzle["created_at"]),
            "body" => puzzle["body"],
            "file" => puzzle["file"],
            "lines" => puzzle["lines"]
        }
    end
end


main
