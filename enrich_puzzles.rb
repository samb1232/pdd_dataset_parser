# Adds data from XML files to JSON files

require 'json'
require 'rexml/document'
require 'fileutils'

input_dir = 'res/pdd_projects_with_issues'
output_dir = 'res/enriched_pdd_projects'
xml_base_dir = 'data/0pdd-dataset'

# Ensure output directory exists
FileUtils.mkdir_p(output_dir)

# Helper to recursively parse puzzles from XML
def parse_xml_puzzles(xml_path)
  unless File.exist?(xml_path)
    puts "Warning: XML file not found at #{xml_path}"
    return {} 
  end
  
  begin
    file = File.new(xml_path)
    doc = REXML::Document.new(file)
    puzzles = {}
    
    # Root puzzles are direct children of the <puzzles> tag
    doc.elements.each('puzzles/puzzle') do |element|
      traverse_puzzle(element, 0, "", puzzles)
    end
    puzzles
  rescue => e
    puts "Error parsing #{xml_path}: #{e.message}"
    {}
  end
end

# Recursive traversal function
def traverse_puzzle(element, hierarchy, parent_id, puzzles)
  id_elem = element.elements['id']
  id = id_elem ? id_elem.text : nil
  return if id.nil?

  estimate = (element.elements['estimate'] ? element.elements['estimate'].text : "")
  file = (element.elements['file'] ? element.elements['file'].text : "")
  lines = (element.elements['lines'] ? element.elements['lines'].text : "")
  author = (element.elements['author'] ? element.elements['author'].text : "")
  
  children_wrapper = element.elements['children']
  # In REXML, we can iterate over elements named 'puzzle' inside 'children'
  child_puzzles = []
  if children_wrapper
    children_wrapper.elements.each('puzzle') do |cp|
      child_puzzles << cp
    end
  end
  
  has_children = !child_puzzles.empty?
  
  puzzles[id] = {
    "estimate" => estimate,
    "file" => file,
    "lines" => lines,
    "author" => author,
    "hierarchy" => hierarchy,
    "parent_id" => parent_id,
    "has_children" => has_children
  }
  
  child_puzzles.each do |child|
    traverse_puzzle(child, hierarchy + 1, id, puzzles)
  end
end

# Processing all JSON files
json_files = Dir.glob(File.join(input_dir, '*.json'))
total_files = json_files.size
puts "Found #{total_files} JSON files to process."

json_files.each_with_index do |json_path, index|
  begin
    data = JSON.parse(File.read(json_path))
    project_link = data['project_link']
    
    if project_link.nil? || project_link.empty?
      puts "Skipping #{json_path}: NO project_link found."
      next
    end

    # Extract owner and repo from project_link (e.g., https://github.com/yegor256/0pdd)
    project_link = project_link.chomp('/')
    parts = project_link.split('/')
    repo = parts.pop
    owner = parts.pop
    
    xml_path = File.join(xml_base_dir, owner, "#{repo}.xml")
    puzzle_meta = parse_xml_puzzles(xml_path)
    
    if data['issues']
      data['issues'].each do |issue|
        id = issue['id']
        if puzzle_meta[id]
          # Update or Add the fields
          issue.merge!(puzzle_meta[id])
        else
          # Initialize with defaults if not found in XML
          issue["estimate"] ||= ""
          issue["author"] ||= ""
          issue["hierarchy"] ||= 0
          issue["parent_id"] ||= ""
          issue["has_children"] ||= false
        end
      end
    end
    
    output_path = File.join(output_dir, File.basename(json_path))
    File.write(output_path, JSON.pretty_generate(data))
    
    if (index + 1) % 10 == 0 || (index + 1) == total_files
      puts "Progress: #{index + 1}/#{total_files} files processed."
    end
  rescue => e
    puts "Error processing #{json_path}: #{e.message}"
  end
end

puts "Successfully enriched #{total_files} files."
puts "Enriched dataset saved to: #{File.absolute_path(output_dir)}"
