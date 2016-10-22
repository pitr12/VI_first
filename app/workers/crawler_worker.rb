require 'sidekiq'

class CrawlerWorker
  include Sidekiq::Worker

  def perform(page_id, court_id, delay)
    sleep(delay)
    page = Downloader.download_page(page_id.to_s.rjust(6, "0"), court_id)
    if page
      Crawler.extract_attributes(page, page_id, court_id)

      File.open("#{File.expand_path File.dirname(__FILE__)}/../../lib/pages/page_#{page_id}_#{court_id}.html", 'w') do |f|
        f.puts(page)
      end
    end
  end

end