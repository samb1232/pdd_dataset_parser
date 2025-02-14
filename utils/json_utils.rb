require "json"
require 'fileutils'


def json_string_to_hash_arr(json_str)
  return JSON.parse(json_str)
end

def write_json_array_to_file(json_array, file_path)
  ensure_directories_exist(file_path)
  File.open(file_path, 'w') do |file|
    file.write(JSON.pretty_generate(json_array))
  end
end


def ensure_directories_exist(file_path)
  directory_path = File.dirname(file_path)

  unless File.directory?(directory_path)
    FileUtils.mkdir_p(directory_path)
  end
end