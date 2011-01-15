require 'sequel'
require 'logger'

DB_ENV rescue  DB_ENV = 'app'
Sequel::Model.plugin(:schema)
if DB_ENV == 'test'
  DB = Sequel.sqlite('test.db')
else
  DB = Sequel.sqlite('app.db')
end

module ::Model
  class Item < Sequel::Model
    set_schema do
      primary_key :id
      String :uri, :null => false, :unique => true
      String :cookie
      String :user_agent

      String :status, :null => false, :default => 'yet'
      Integer :retry_count, :null => false, :default => 0

      DateTime :created_at
      DateTime :updated_at
    end
    create_table unless table_exists?

    def self.files_root
      File.expand_path(ENV['DOZO_FILES_ROOT'] || File.join(File.dirname(__FILE__), '..', 'files'))
    end

    def self.setup_directory
      unless File.exists? files_root
        warn "mkdir #{files_root}"
        Dir.mkdir files_root
      end
    end

    def wget_command
      command = ['wget', '--progress=dot:mega', '--no-check-certificate', '-c']
      if self.cookie
        command << '--header'
        command << "'Cookie: #{self.cookie}'"
      end

      if self.user_agent
        command << "--user-agent='#{self.user_agent}'"
      end

      command << '-O'
      command << "'#{self.local_path}'"

      command << "'#{self.uri}'"
      command << "2>&1"

      command.join(" ")
    end

    def delete_file
      File.delete(self.local_path) if File.exists? self.local_path
    end

    def filename
      self.uri.split('/').last
    end

    def local_uri
      '/files/' + self.filename
    end

    def local_path
      File.join(self.class.files_root, filename)
    end

    def filesize
      size = File.stat(self.local_path).size rescue 0
      suffixes = %w{B KB MB GB}
      index = 0
      while size >= 1024.0
        size /= 1024.0
        index += 1
      end
      "%.1f#{suffixes[index]}" % size
    end

    def yet!
      self.status = 'yet'
      self.save
    end

    def process!
      self.status = 'process'
      self.save
    end

    def done!
      self.status = 'done'
      self.save
    end

    def done?
      self.status == 'done'
    end

    def failed?
      self.status == 'failed'
    end

    def failed!
      self.retry_count += 1
      if self.retry_count == 10
        self.status = 'failed'
      else
        self.status = 'yet'
      end
      self.save
    end

    def reset!
      self.delete_file
      self.retry_count = 0
      self.status = 'yet'
      self.save
    end


    plugin :timestamps, :update_on_create => true

  end
end
