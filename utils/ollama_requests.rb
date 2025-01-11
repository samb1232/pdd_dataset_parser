require "json"
require 'uri'
require 'net/http'


def generate_ollama_response(prompt)
  model_name = "llama3"
  stream = false

  uri = URI.parse("http://localhost:11434/api/generate")
  http = Net::HTTP.new(uri.host, uri.port)

  prompt_hash = {
    "model": model_name,
    "prompt": prompt,
    "stream": stream
  }
  request_body = prompt_hash.to_json

  request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
  request.body = request_body

  response = http.request(request)
  response_json = JSON.parse(response.body)
  return response_json["response"]
end
