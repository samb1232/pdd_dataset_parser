require_relative "../utils/json_utils"


def main() 
    data = json_string_to_hash_arr(File.read("results\\data_xml_by_timestamps.json"))
    prompts = make_prompts(data)

    write_json_array_to_file(prompts, "prompts.json")
end


def make_prompts(puzzles_collections)
    prompts = []
    puzzles_collections.each do |puzzle_collection|

        puzzles_len = puzzle_collection["puzzles_len"]
        project_name = puzzle_collection["project_name"]
        prompt = "I have github project: #{project_name}. Currentrly it has #{puzzles_len} issues. I give you information about them: "

        puzzles = puzzle_collection["puzzles"]
        puzzles.each do |puzzle|
            puzzle_info = "{"
            puzzle_info += "id: #{puzzle["id"]}, "
            puzzle_info += "created_at: #{puzzle["created_at"]}, "
            puzzle_info += "body: \"#{puzzle["body"]}\", "
            puzzle_info += "file: #{puzzle["file"]}, "
            puzzle_info += "lines: #{puzzle["lines"]}"
            puzzle_info += "}"
            prompt += puzzle_info + ","
        end

        prompt += ". I want you to chose one issue, that you think is the most priority than others. Do not explain yourself, write only full id of chosen issue and nothing more."
        
        chosen_puzzle_id = puzzle_collection["chosen_puzzle_id"]
        prompts << {"prompt" => prompt, "answer" => chosen_puzzle_id}
    end

    return prompts
end


main
