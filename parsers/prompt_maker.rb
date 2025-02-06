require "date"
require_relative "../utils/json_utils"


def main() 
    data = json_string_to_hash_arr(File.read("data_xml_by_timestamps_v2.json"))
    prompts = make_prompts(data)

    write_json_array_to_file(prompts, "prompts.json")
end


def make_prompts(puzzles_collections)
    prompts = []
    puzzles_collections.each do |puzzle_collection|

        puzzles_len = puzzle_collection["puzzles_len"]
        next if puzzles_len > 30

        project_name = get_project_name_from_link(puzzle_collection["project_name"])
        prompt = "I have a GitHub project titled \"#{project_name}\". Currently, there are #{puzzles_len} issues. "
        prompt += "Each issue was automaticly generated based on programmer's description in code. Here are the details: "
        puzzles = puzzle_collection["puzzles"]
        puzzles.each do |puzzle|
            puzzle_creation_date_prettified = prettify_date(puzzle["created_at"])
            puzzle_info = "Issue with id \"#{puzzle["id"]}\" was created #{puzzle_creation_date_prettified}."
            puzzle_info += "In this issue the programmer stated: \"#{puzzle["body"]}\". The affected file is: #{puzzle["file"]}. "
            prompt += puzzle_info
            prompt += "\n"
        end

        prompt += "I would like you to select one issue that you believe is of the highest priority and should be addressed more urgently than the other. "
        # prompt += "Do not explain yourself, write only full id of chosen issue and nothing more."
        
        chosen_puzzle_id = puzzle_collection["chosen_puzzle_id"]
        prompts << {"prompt" => prompt, "answer" => chosen_puzzle_id}
    end

    return prompts
end

def get_project_name_from_link(project_link)
    project_link.split("/").last
end


def prettify_date(date_str)
    date = DateTime.parse(date_str)
    return date.strftime("%d.%m.%Y")
end


main
