def create_prompt_from_puzzles(puzzles)
  prompt = ""
  puzzles.each do |puzzle|
    prompt += "Issue ID: #{puzzle["id"]}\n"
    prompt += "Created: #{puzzle["created_at"]}\n"
    prompt += "Body: #{puzzle["body"]}\n"
    prompt += "File: #{puzzle["file"]}:#{puzzle["lines"]}\n\n"
  end
  prompt
end
