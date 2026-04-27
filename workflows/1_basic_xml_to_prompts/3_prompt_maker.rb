require_relative "../../utils/json_utils"
require_relative "../../utils/prompt_utils"
require_relative "../../utils/date_utils"
require_relative "../../utils/project_utils"

def make_prompts(puzzles_collections)
  puzzles_collections.map do |puzzle_collection|
    puzzles_len = puzzle_collection["puzzles_len"]
    next if puzzles_len > 30

    project_name = get_project_name_from_link(puzzle_collection["project_name"])
    
    prompt = "I have a GitHub project titled \"#{project_name}\". Currently, there are #{puzzles_len} issues. "
    prompt += "Each issue was automatically generated based on programmer's description in code. Here are the details:\n"
    
    puzzle_collection["puzzles"].each do |puzzle|
      creation_date = prettify_date(puzzle["created_at"])
      prompt += "Issue with id \"#{puzzle["id"]}\" was created #{creation_date}. "
      prompt += "In this issue the programmer stated: \"#{puzzle["body"]}\". The affected file is: #{puzzle["file"]}.\n"
    end

    prompt += "\nI would like you to select one issue that you believe is of the highest priority and should be addressed more urgently than the other. "
    prompt += "Do not explain yourself, write only full id of chosen issue and nothing more."
    
    { "prompt" => prompt, "answer" => puzzle_collection["chosen_puzzle_id"] }
  end.compact
end

def main
  input_file = "dataset_xml_by_timestamps.json"
  unless File.exist?(input_file)
    puts "Input file #{input_file} not found."
    return
  end

  data = load_json_file(input_file)
  prompts = make_prompts(data)

  write_json_array_to_file(prompts, "prompts_for_long_explaining.json")
  puts "Generated prompts_for_long_explaining.json"
end

main if __FILE__ == $0
