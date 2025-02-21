require_relative "../utils/json_utils"


def main() 
    data = json_string_to_hash_arr(File.read("results\\data_simple_chronographic.json"))
    prompts = make_prompts(data)

    write_json_array_to_file(prompts, "prompts_survey.json")
end


def make_prompts(puzzles_collections)
    prompts = []
    puzzles_collections.each do |puzzle_collection|
        prompt = "INTRODUCTION"
        prompt += "EXPLAINING CONCEPT OF PUZZLE"
        prompt += "I will provide you with information about current active puzzles in my project in chronological order (from oldest to newest): "

        puzzle_collection["puzzles"].each do |puzzle|
            prompt += create_prompt_from_puzzle(puzzle)
        end
        
        


        prompt += "EXPLAINING PRIORITY CRITERIA"
        prompt += "Help me decide what puzzle should i solve first."
        prompts << prompt
    end

    return prompts
end


main
