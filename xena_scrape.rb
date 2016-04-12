#!/usr/bin/ruby
require 'optparse'
require 'json'
require 'open-uri'
require 'nokogiri'

#Argument handling
options = {}
OptionParser.new do |opts|
  opts.banner = "Xena_Scrape: Downloading lots of bird calls from Xeno-Canto. http://github.com/willpearse/Xena\nUsage: xena_scrape.rb [options]"
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.on("-f FILE", "--file FILE", "File with birds to search") {|x| options[:file] = x.to_s}
  opts.on("-o FILE", "--output FILE", "Name of output") {|x| options[:output] = x.to_s}
  opts.on("-c NUMBER", "--count NUMBER", "Number of records to download (max)") {|x| options[:count] = x.to_i}
  opts.on("-")
end.parse!

File.open(options[:output], "w") do |handle|
  open(options[:file]).each do |bird|
    begin    
      output = Hash[["search","id","gen","sp","ssp","en","rec","cnt","loc","lat","lng","type","file","lic","url","q","Date","Time","Elevation","Background","Length","Sampling rate","Comments"].collect { |v| [v, []] }]
      
      url = URI.encode "http://www.xeno-canto.org/api/2/recordings?query=#{bird.chomp} q:A"
      result = JSON.parse(open(url).read)
      
      result["recordings"].each_with_index do |record, i|
        unless i < options[:count] then break end
        output["search"].push bird.chomp
        #Grab API description
        record.each {|key, value| output[key].push(value)}
        
        #Grab data from HTML description
        page = Nokogiri::HTML(open(record["url"]))
        #Table entries
        curr_key = ""
        page.css("td").each do |entry|
          unless curr_key.empty? then output[curr_key] = entry.text end
          if output.keys.include?(entry.text)
            curr_key = entry.text
          else
            curr_key = ""
          end
        end
        
        #Paragraph details
        comments = ""
        page.css("p").each do |entry|
          if entry.text=="Rate the quality of this recording (A is best, E worst):" then break end
          comments += entry.text
        end
        output["Comments"].push comments
      end
      
      #Write output - euck, sorry
      output["search"].each_with_index do |each, i|
        handle << "#{output.keys.map {|x| output[x][i].to_s}.join(",")}\n"
      end
      puts bird
      sleep 30
    rescue
      puts "Server error"
      sleep 300
    end
  end
end
