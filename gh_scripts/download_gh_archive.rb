require 'fileutils'
require 'net/http'
require 'date'

OUT_DIR = "gharchive_2023"
FileUtils.mkdir_p(OUT_DIR)

# Download archives for the 15th of each month in 2023 (12 total)
(1..12).each do |month|
  date = Date.new(2023, month, 15)
  date_str = date.strftime("%Y-%m-%d")
  hour = 0 # Picking hour 0 for each day
  
  url_str = "https://data.gharchive.org/#{date_str}-#{hour}.json.gz"
  file_path = File.join(OUT_DIR, "#{date_str}-#{hour}.json.gz")

  if File.exist?(file_path)
    puts "Already downloaded #{file_path}"
    next
  end

  puts "Downloading #{url_str}"
  uri = URI(url_str)
  
  begin
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |response|
        if response.is_a?(Net::HTTPSuccess)
          File.open(file_path, 'wb') do |file|
            response.read_body do |chunk|
              file.write(chunk)
            end
          end
        else
          puts "Failed #{url_str}: #{response.code}"
        end
      end
    end
  rescue => e
    puts "Error downloading #{url_str}: #{e.message}"
  end
end
