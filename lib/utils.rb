require 'fileutils'
require 'logger'

module Utils

  @@basedir = "#{Dir.home}/.config/fdcli"
  @@token = nil
  @@org = nil
  @@apiurl = nil
  @@log = nil

  def self.log
    if @@log.nil?
      p "HEERE"
      p @@basedir
      p "HEERE"
      FileUtils.mkdir_p @@basedir
      f = File.open "#{@@basedir}/fdcli.log", File::WRONLY | File::APPEND | File::CREAT
      f.sync = true
      f.truncate 0
      @@log = Logger.new f
    end
    @@log
  end

  def self.init_config
    h = {}
    begin
      File.open "#{@@basedir}/config", 'r' do |file|
        file.each do |line|
          t = line.split(':')
          h[t[0]] = t[1].strip
        end
      end
      @@token = h['token']
      @@org = h['org']
      @@apiurl = "https://#{@@token}@api.flowdock.com"
    rescue
      fatal_token_error
    end
  end

  class P
    def self.|(v)
      if @cur.nil?
        @cur = v
        return self
      end
      @cur = v.call(@cur)
      self
    end
  end
  alias_method :C, :method

  def self.fatal_token_error
    puts <<END
Please make sure you have your personal API token and the name of
your Flowdock organization in #{@basedir}/config

Get the API token on https://www.flowdock.com/account/tokens

#{@basedir}/config should look roughly like this:

org: my-flowdock-org
token: b8227198b8ef6c57e2f55e34c3722706

END
    exit 2
  end
end
