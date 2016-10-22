#!/usr/bin/env ruby
require File.expand_path('../../config/environment',  __FILE__)
require 'nokogiri'

class TypeDetectionCrawler
  def self.extract_and_save_types(page)
    types = []
    @doc = Nokogiri::HTML(page)
    @doc.xpath("//table[not(ancestor::table)]/tr[1]/td[1]/span[@class='tl']/text()").each do |type|
      types << type.to_s.sub(':','')
    end

    File.open("#{File.dirname(__FILE__)}/types.txt", 'a') do |f|
      f.puts(types)
    end
  end

end

# iterate over pageIds and courtIds to download desired pages and extract all possible types
if ARGV.size > 0
  (1..ARGV[0].to_i).each do |index|
    page_id = rand(1..400000)
    (2..9).each do |court_id|
      TypesCrawlerWorker.perform_async(page_id, court_id, 1)
    end
  end
end

if ARGV.size == 0
  types = File.foreach("#{File.dirname(__FILE__)}/types.txt").map{|x| x.chomp}
  File.open("#{File.dirname(__FILE__)}/types.txt", 'w') do |f|
    f.puts(types.uniq)
  end
end