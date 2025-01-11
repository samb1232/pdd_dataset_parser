require_relative "utils/ollama_requests"
require_relative "utils/json_utils"


def main
    prompts = json_string_to_hash_arr(File.read("results\\prompts_v2.json"))
    success_cnt = 0
    total_cnt = 0
    prompts.each do |prompt|
        total_cnt += 1
        prompt_body = prompt["prompt"]
        prompt_answer = prompt["answer"]
        response = generate_ollama_response(prompt_body)

        success = response.include?(prompt_answer)

        if success
            success_cnt += 1
        end
        puts "-----------------------------"
        puts "Response: #{response}"
        puts "Answer: #{prompt_answer}"
        puts "Success: #{success}"
        puts "-----------------------------"
        puts "Statistic: #{success_cnt}/#{total_cnt}"
    end
end


main
