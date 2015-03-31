#!/usr/bin/ruby
require 'optparse'
require 'json'
require 'open-uri'

options = {}
OptionParser.new do |opts|
  #Defaults
  options[:number] = 1
  options[:quality] = "A"
  
  opts.banner = "wl: Will's Libary of Will. http://github.com/willpearse/wl\nUsage: wl.rb [options]"
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on("-b BIRD", "--bird BIRD", "Which BIRD to download") {|x| options[:bird] = x.to_s}
  opts.on("-n NUMBER", "--number NUMBER", "Download NUMBER songs") {|x| options[:number] = x.to_i}
  opts.on("-q QUALITY", "--quality QUALITY", "What QUALITY to download") {|x| options[:quality] = x.to_s}
  opts.on("-")
end.parse!

url = URI.encode "http://www.xeno-canto.org/api/2/recordings?query=#{options[:bird]} q:#{options[:quality]}"
result = JSON.parse(open(url).read)
count = 0
result["recordings"].each_with_index do |dwn, i|
  if count < options[:number]
    File.open("#{options[:bird]}_#{i}", "w") {|x| x << open(dwn["file"])}
    count += 1
  else
    break
  end
end

puts "#{result["recordings"].length} found; #{count} downloaded"
