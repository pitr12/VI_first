#!/usr/bin/env ruby
require File.expand_path('../../config/environment',  __FILE__)
require 'nokogiri'
require 'faraday'
require 'elasticsearch'
require 'json'

class FileProcessor

  def self.parse_files

    index = 0
    Dir.foreach("#{File.expand_path File.dirname(__FILE__)}/pages") do |item|
      next if item == '.' or item == '..'

      page = File.open("#{File.expand_path File.dirname(__FILE__)}/pages/#{item}", 'r').read
      arr = item.split('_')
      page_id = arr[1]
      court_id = arr[2].match(/\d/)

      puts "processing page: " + item.to_s

      Crawler.extract_attributes(page, page_id, court_id)
      index += 1
    end
    puts "Procecessed #{index} files"
  end

  def self.evaluate_response(response)
    success = 0
    response["items"].each do |item|
      success += item["create"]["_shards"]["successful"].to_i
    end

    puts "#{success} / #{response["items"].size} items processed successfully"
  end

  def self.populate_elastic
    start = Time.now
    client = Elasticsearch::Client.new log: false
    json = JSON.parse(File.read("#{File.expand_path File.dirname(__FILE__)}/result.json"));

    body = []
    overall_index = json.size
    # json.each_with_index do |company, index|
    #   overall_index = index
    #   body << { index:  { _index: 'vi', _type: 'companies', data: company } }
    #   if index != 0 && index % 300 == 0
    #     response = client.bulk body: body
    #     evaluate_response(response)
    #     body = []
    #   end
    # end
    #
    # if body.size > 0
    #   client.bulk body: body
    # end

    finish = Time.now
    diff = finish - start

    puts "-------------------------------------------"
    puts "Processed #{overall_index + 1} entries"
    puts "Total execution time: #{diff / 60} min"
    puts "-------------------------------------------"
    # puts json.size
  end

end

# FileProcessor.parse_files
FileProcessor.populate_elastic