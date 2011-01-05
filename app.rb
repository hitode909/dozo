class DozoApp < Sinatra::Base

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  set :haml, :escape_html => true

  configure do
    Model::Item.setup_directory
    DozoApp.logger.info "files root is #{Model::Item.files_root}"
  end

  get '/' do
    @items = Model::Item.order(:created_at.desc).all || []
    haml :index
  end

  post '/' do
    Model::Item.create(
      :uri => params[:uri],
      :cookie => params[:cookie],
      :user_agent => params[:uset_agent]
      )
    DozoApp.logger.info "new item #{params[:uri]}"
    'ok'
  rescue => error
    DozoApp.logger.warn error.message
    halt 500
  end

  post '/delete' do
    item = Model::Item.find(
      :uri => params[:uri]
      )
    halt 404 unless item
    DozoApp.logger.info "delete item #{item.uri}"
    item.delete_file
    item.delete
    'ok'
  end

  post '/reset' do
    item = Model::Item.find(
      :uri => params[:uri]
      )
    halt 404 unless item
    halt 400 unless item.failed?
    item.reset!
    DozoApp.logger.info "reset item #{item.uri}"
    'ok'
  end

  get '/files/:path' do
    path = File.expand_path(File.join(Model::Item.files_root, unescape(params[:path])))
    halt 404 unless File.exists?(path)

    DozoApp.logger.info "send file #{path}"
    env['sinatra.static_file'] = path
    send_file path, :disposition => nil
  end

end
