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
    # TODO
    # rescue SignalException => error
    #   @logger.warn "kill wget process"
    #   Process.kill('KILL', @io.pid)# if @io
    #   raise error
  end

  def download(item)
    logger.info "download #{item.uri}"

    item.process!

    logger.info item.wget_command
    self.wget(item.wget_command)
    logger.info "done: #{item.uri}, #{item.filesize}"

    item.done!
  rescue => error
    logger.warn "failed: #{error.class}, #{error.message}"
    item.failed!
  end

  def wget(command)
    @io = IO.popen command, 'r+'
    buffer = ''
    loop {
      chr = @io.read 1
      break if chr.nil?
      buffer << chr
      if chr =~ /[\r\n]/
        buffer.chomp!
        logger.info buffer unless buffer.empty?
        buffer = ''
      end
    }
    @io = nil
  end
end
