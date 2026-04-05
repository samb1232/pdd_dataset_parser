require "date"

def fix_date_format(date_string)
  return nil if date_string.nil?

  datetime = DateTime.parse(date_string)
  datetime.strftime('%Y-%m-%dT%H:%M:%SZ')
end

def prettify_date(date_str)
  return nil if date_str.nil?

  date = DateTime.parse(date_str)
  date.strftime("%d.%m.%Y")
end

def parse_datetime(date_string)
  return nil if date_string.nil?

  DateTime.parse(date_string)
end