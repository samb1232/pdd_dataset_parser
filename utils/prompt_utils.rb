require "date"

def get_project_name_from_link(project_link)
    project_link.split("/").last
end


def prettify_date(date_str)
    date = DateTime.parse(date_str)
    return date.strftime("%d.%m.%Y")
end
