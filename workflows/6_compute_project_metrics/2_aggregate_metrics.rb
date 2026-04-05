require 'json'

def compute_median(sorted_values)
  count = sorted_values.length
  return nil if count == 0
  
  mid = count / 2
  if count.odd?
    sorted_values[mid]
  else
    (sorted_values[mid - 1] + sorted_values[mid]) / 2.0
  end
end

def compute_iqr(sorted_values)
  count = sorted_values.length
  return nil if count < 2
  
  mid = count / 2
  if count.odd?
    lower_half = sorted_values[0...mid]
    upper_half = sorted_values[(mid + 1)...count]
  else
    lower_half = sorted_values[0...mid]
    upper_half = sorted_values[mid...count]
  end
  
  q1 = compute_median(lower_half)
  q3 = compute_median(upper_half)
  
  return nil if q1.nil? || q3.nil?
  q3 - q1
end

def compute_statistics(values)
  # Filter out nil or non-numeric values
  valid_values = values.select { |v| v.is_a?(Numeric) }
  count = valid_values.length
  
  return {
    "count" => 0,
    "mean" => nil,
    "median" => nil,
    "standard_deviation" => nil,
    "min" => nil,
    "max" => nil,
    "interquartile_range" => nil
  } if count == 0

  sorted = valid_values.sort
  min_val = sorted.first
  max_val = sorted.last
  
  sum = valid_values.sum
  mean = sum.to_f / count
  
  median = compute_median(sorted)
  iqr = compute_iqr(sorted)
  
  if count < 2
    std_dev = nil
  else
    variance_sum = valid_values.reduce(0) { |acc, val| acc + (val - mean)**2 }
    std_dev = Math.sqrt(variance_sum / (count - 1))
  end
  
  {
    "count" => count,
    "mean" => mean.round(4),
    "median" => median ? median.round(4) : nil,
    "standard_deviation" => std_dev ? std_dev.round(4) : nil,
    "min" => min_val.round(4),
    "max" => max_val.round(4),
    "interquartile_range" => iqr ? iqr.round(4) : nil
  }
end

if ARGV.length < 2
  puts "Usage: ruby 2_aggregate_metrics.rb <input_metrics.json> <output_summary.json>"
  exit 1
end

input_file = ARGV[0]
output_file = ARGV[1]

unless File.exist?(input_file)
  puts "Error: Input file '#{input_file}' does not exist."
  exit 1
end

data = JSON.parse(File.read(input_file))

# Expect array of repository objects
unless data.is_a?(Array)
  puts "Error: Input JSON must be an array of repository objects."
  exit 1
end

target_metrics = [
  "issue_body_size_average",
  "mean_time_to_resolution_days",
  "average_comments_per_issue",
  "average_events_per_issue",
  "label_rate",
  "assignee_rate"
]

metric_values = Hash.new { |h, k| h[k] = [] }

data.each do |repo|
  target_metrics.each do |metric|
    val = repo[metric]
    metric_values[metric] << val unless val.nil?
  end
end

results = {
  "repositories_count" => data.length,
  "metrics" => {}
}

target_metrics.each do |metric|
  results["metrics"][metric] = compute_statistics(metric_values[metric])
end

File.write(output_file, JSON.pretty_generate(results))
puts "Successfully processed #{data.length} repositories."
puts "Summary statistics written to '#{output_file}'."
