require "json"

def read_json_string(json_str)
  return JSON.parse(json_str)
end

def write_json_array_to_file(json_array, file_path)
  File.open(file_path, 'w') do |file|
    file.write(JSON.pretty_generate(json_array))
  end
end