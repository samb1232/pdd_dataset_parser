def fix_date_format(date_string)
    if date_string.nil?
        return nil
    end
    datetime = DateTime.parse(date_string)
    formatted_date = datetime.strftime('%Y-%m-%dT%H:%M:%SZ')
    return formatted_date
end