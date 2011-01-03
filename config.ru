$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + '/lib')

require 'sinatra/base'
require 'haml'
require 'model'
require 'downloader'
require 'logger'
require 'app'

Thread.new {
  Downloader.new.run
}

run DozoApp
