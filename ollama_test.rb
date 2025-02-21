require_relative "utils/ollama_requests"
require_relative "utils/json_utils"


def main
    prompts = json_string_to_hash_arr(File.read("prompts_for_long_explaining.json"))
    prompt_suffix = "   "
    success_cnt = 0
    total_cnt = 0
    prompts.each do |prompt|
        total_cnt += 1
        prompt_body = prompt["prompt"]
        prompt_answer = prompt["answer"]
        response_long = generate_ollama_response(prompt_body)
        response_short = generate_ollama_response(prompt_body + prompt_suffix)

        success = response_short.include?(prompt_answer)

        if success
            success_cnt += 1
        end

        puts "-----------------------------"
        puts "Prompt: #{prompt_body}"
        puts "Response: #{response_long}"
        puts "Answer: #{prompt_answer}"
        puts "Success: #{success}"
        puts "-----------------------------"
        puts "Statistic: #{success_cnt}/#{total_cnt}"

        append_answer_to_json_file(prompt_body, response_long, response_short, prompt_answer, "answers.json")
    end
end


def append_answer_to_json_file(prompt_body, response_long, response_short, prompt_answer, json_filepath)
    if File.file?(json_filepath)
        answers = json_string_to_hash_arr(File.read(json_filepath))
    else
        answers = []
    end
    curr_answer = {
        "prompt": prompt_body,
        "response_long": response_long,
        "response_short": response_short,
        "answer": prompt_answer,
    }
    answers << curr_answer

    write_json_array_to_file(answers, json_filepath)
end


main
