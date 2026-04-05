def extract_project_link(issue_link)
  return nil if issue_link.nil?
  
  issue_link.split("/issues/")[0]
end

def get_project_name_from_link(project_link)
  return "unknown-project" if project_link.nil?
  
  project_link.split("/").last
end
