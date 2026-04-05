require 'json'
require 'securerandom'

def main
  file_path = 'selected_projects_2023_2025.json'
  projects = JSON.parse(File.read(file_path))

  small = []
  medium = []
  large = []

  projects.each do |p|
    cnt = p['closed_issues_count'] || 0

    if cnt < 100
      small << p
    elsif cnt >= 100 && cnt <= 200
      medium << p
    elsif cnt > 200 && cnt <= 400
      large << p
    end
  end

  puts "Total small: #{small.size}"
  puts "Total medium: #{medium.size}"
  puts "Total large: #{large.size}"

  # We want 300 total, ideally 100 each.
  # Shuffle each category first.
  srand(42) # For reproducibility
  small.shuffle!
  medium.shuffle!
  large.shuffle!

  selected = small.take(100) + medium.take(100) + large.take(100)

  puts "Selected: #{selected.size}"

  File.open('300_selected_projects.json', 'w') do |f|
    f.write(JSON.pretty_generate(selected))
  end
end

main if __FILE__ == $PROGRAM_NAME
