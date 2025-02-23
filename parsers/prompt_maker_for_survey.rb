require_relative "../utils/json_utils"
require_relative "../utils/prompt_utils"

def main() 
    data = json_string_to_hash_arr(File.read("results\\data_simple_chronographic.json"))
    prompts = make_prompts(data)

    write_json_array_to_file(prompts, "prompts_survey.json")
end


def make_prompts(puzzles_collections)
    prompts = []
    puzzles_collections.each do |puzzle_collection|
        puzzles_len = puzzle_collection["puzzles_len"]
        next if puzzles_len > 6

        project_name = get_project_name_from_link(puzzle_collection["project_name"])
        
        prompt = "I am working on a GitHub project titled \"#{project_name}\". "
        prompt += "I use metodology of creating issues as \"puzzles\". When a programmer discovers error or possible improvement, he writes a comment in code, that is determened as \"puzzle\". "
        prompt += "Then special program automaticly collects this puzzles in code and creates Github issue for each puzzle."
        prompt += "\n\n"
        prompt += "Currently, there are #{puzzles_len} puzzles. "
        prompt += "I will provide you with information about current active puzzles in my project in chronological order (from oldest to newest): "

        prompt += create_prompt_from_puzzles(puzzle_collection["puzzles"])
        
        prompt += "I would like you to decide what puzzle should i solve first. "
        prompt += "Consider the following criteria: "

        prompt += "Do not explain yourself, write only id of chosen puzzle and nothing more."
        
        prompts << prompt
    end

    return prompts
end


def create_prompt_from_puzzles(puzzles)
    prompt = ""

    puzzles.each do |puzzle|
        prompt += "PUZZLE. "
    end

    return prompt
end

main
