require 'sidekiq'

class TypesCrawlerWorker
  include Sidekiq::Worker

  def perform(page_id, court_id, delay)
    sleep(delay)
    page = Downloader.download_page(page_id.to_s.rjust(6, "0"), court_id)
    TypeDetectionCrawler.extract_and_save_types(page)
  end

end