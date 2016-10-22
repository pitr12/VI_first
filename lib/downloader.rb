require 'faraday'
require 'nokogiri'

class Downloader

  PROXY = [
    'http://147.75.209.32:10200',
    '',
    '',
    'http://147.75.209.48:10200',
    '',
    '',
    'http://46.143.225.70:3128',
    '',
    '',
    'http://123.30.238.16:3128',
    '',
    '',
    'http://179.60.214.54:8080'
  ]

  def self.download_page(page_id, court_id)
    conn = Faraday.new(:url => 'http://www.orsr.sk', :proxy => PROXY[rand(0..PROXY.size-1)]) do |faraday|
      faraday.request  :url_encoded
      faraday.adapter  Faraday.default_adapter
    end

    response = conn.get do |req|
      req.url '/vypis.asp'
      req.params['ID'] = page_id
      req.params['SID'] = court_id
      req.params['P'] = 0
    end

    response.body.force_encoding('windows-1250')
    response.body.encode('utf-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
  end

end

# body = Downloader.download_page(8657,2)
# File.open("#{File.dirname(__FILE__)}/page.html", 'w') do |f|
#   f.puts(body)
# end