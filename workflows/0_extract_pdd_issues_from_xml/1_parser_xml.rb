require 'find'
require 'rexml/document'
require 'date'
require_relative "../../utils/json_utils"
require_relative "../../utils/github_project_checker"
require_relative "../../utils/date_utils"
require_relative "../../utils/project_utils"

include REXML

DATASET_DIR_PATH = "./data/pdd_xml"

def main
  project_puzzles = []
  counter = 1
  
  xml_files = Find.find(DATASET_DIR_PATH).select { |path| xml_file?(path) }
  total_files = xml_files.count

  xml_files.each do |path|
    new_puzzles = extract_puzzles_from_xml(path)
    project_puzzles.concat(new_puzzles)
    puts "Progress: #{counter}/#{total_files}"
    counter += 1
  end

  write_json_array_to_file(project_puzzles, "puzzle_related_data_from_xml.json")
end

def xml_file?(filepath)
  File.file?(filepath) && File.extname(filepath) == ".xml"
end

def extract_puzzles_from_xml(xml_filepath)
  File.open(xml_filepath) do |file|
    doc = Document.new(file)
    root = doc.root
    puzzles_list = root.elements.to_a
    convert_puzzles_to_hashes(puzzles_list)
  end
end

def convert_puzzles_to_hashes(puzzles, project_link = nil)
  project_link ||= find_project_link(puzzles)
  return [] if project_link.nil?

  puzzle_hashes = []

  puzzles.each do |puzzle_node|
    attributes = puzzle_node.attributes
    elements = puzzle_node.elements

    issue_node = elements["issue"]
    issue_link = issue_node&.attributes&.[]("href")

    closed_at = issue_node&.attributes&.[]("closed")
    formatted_closed_at = closed_at ? fix_date_format(closed_at) : nil

    # Recursively process children
    children = elements["children"].elements
    if children.size > 0
      child_puzzles = convert_puzzles_to_hashes(children.to_a, project_link)
      puzzle_hashes.concat(child_puzzles)
    end

    puzzle_hashes << {
      'project_link' => project_link,
      'issue_link'   => issue_link,
      'ticket'       => elements["ticket"]&.text,
      'done'         => attributes["alive"] == "false",
      'id'           => elements["id"]&.text,
      'closed_at'    => formatted_closed_at,
      'created_at'   => elements["time"]&.text,
      'body'         => elements["body"]&.text,
      'file'         => elements["file"]&.text,
      'lines'        => elements["lines"]&.text
    }
  end

  puzzle_hashes
end

def find_project_link(puzzles)
  puzzles.each do |puzzle|
    issue_href = puzzle.elements["issue"]&.attributes&.[]("href")
    next unless issue_href

    return extract_project_link(issue_href)
  end
  nil
end

main if __FILE__ == $0