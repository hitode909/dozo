require 'model'
require 'logger'

class Downloader
  def logger
    @logger ||= Logger.new($stdout)
  end

  def run
    loop {
      item = Model::Item.order(:created_at.asc).filter(:status => 'yet').first
      download item if item
      sleep 10
    }
  end

  def download(item)
    logger.info "download #{item.inspect}"

    item.process!

    system *item.wget_command or raise "failed"

    item.done!
  rescue => error
    logger.warn "failed: #{error.class}, #{error.message}"
    item.failed!
  end
end
