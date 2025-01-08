require 'find'
require 'rexml/document'
require_relative "utils/json_utils"
require_relative "utils/github_project_checker"
include REXML


DATASET_DIR = "0pdd-dataset"


def main
    project_puzzles = []
    Find.find(DATASET_DIR) do |path|
        unless path_to_xml?(path) 
           next
        end
        new_puzzles = get_puzzles_from_xml_file(path)
        project_puzzles.concat(new_puzzles)
    end
    write_json_array_to_file(project_puzzles, "NEW_DATASETIK.json")
    puts "DONE!"
end


def path_to_xml?(filepath)
    return File.file?(filepath) && File.extname(filepath) == ".xml"
end


def get_puzzles_from_xml_file(xml_filepath)
    File.open(xml_filepath) do |file|
        doc = Document.new(file)
        root = doc.root
        puzzles_list = root.elements.to_a
        project_hashes = convert_puzzles_to_hashes(puzzles_list)
        return project_hashes
    end
end


def convert_puzzles_to_hashes(puzzles)
    project_link = get_project_link_from_puzzles(puzzles)

    if project_link.nil?
        return []
    end

    is_project_public = check_is_project_public(project_link)

    if !is_project_public
        puts "Private found"
        return []
    end

    puts "Public found"


    project = []

    puzzles.each do |puzzle|
        is_done = puzzle.attributes["alive"] == "false"
        
        p_elements = puzzle.elements

        id = p_elements["id"].text
        body = p_elements["body"].text
        file = p_elements["file"].text
        lines = p_elements["lines"].text
        created_at = p_elements["time"].text

        issue = p_elements["issue"]
        if issue.nil?
            closed_at = nil
        else
            closed_at = issue.attributes["closed"]
        end
        
        children = p_elements["children"].elements
        if children.size > 0
            children_arr = children.to_a
            children_puzzles_hashes = convert_puzzles_to_hashes(children_arr)
            project.concat(children_puzzles_hashes)
        end

        new_puzzle = {
            'project_link' => project_link,
            'done' => is_done,
            'id' => id,
            'closed_at' => closed_at,
            'created_at' => created_at,
            'body' => body,
            'file' => file,
            'lines' => lines,
        } 
        project << new_puzzle
    end


    
    return project
end


def get_project_link_from_puzzles(puzzles)
    puzzles.each do |puzzle|
        issue_element = puzzle.elements["issue"]
        if issue_element.nil?
            next
        end

        issue_href = issue_element.attributes["href"]
        if issue_href.nil?
            next
        end

        project_link = extract_project_link(issue_href)
        return project_link
    end
    return nil
end


def extract_project_link(issue_link)
    issue_link.split("/issues/")[0]
end


main
