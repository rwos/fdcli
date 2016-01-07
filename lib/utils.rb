# utilities for fdcli - Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require 'fileutils'
require 'logger'

module Utils

  BASEDIR = "#{Dir.home}/.config/fdcli"
  # TOKEN
  # ORG
  # APIURL
  # LOG

  def self.log
    unless self.const_defined? :LOG
      FileUtils.mkdir_p BASEDIR
      f = File.open "#{BASEDIR}/fdcli.log", File::WRONLY | File::CREAT
      f.sync = true
      f.truncate 0
      const_set :LOG, (Logger.new f)
    end
    LOG
  end

  def self.init_config
    h = {}
    begin
      File.open "#{BASEDIR}/config", 'r' do |file|
        file.each do |line|
          t = line.split(':')
          h[t[0]] = t[1].strip
        end
      end
      const_set :TOKEN, h['token']
      const_set :ORG, h['org']
      const_set :APIURL, "https://#{TOKEN}@api.flowdock.com"
    rescue
      fatal_token_error
    end
  end

  # Pipe XXX XXX KILL
  class P
    def initialize(v)
      @cur = v
    end
    def |(v)
      @cur = v.call(@cur)
      self
    end
    def to_str
      @cur
    end
  end

  def self.fatal_token_error
    puts <<END
Please make sure you have your personal API token and the name of
your Flowdock organization in #{BASEDIR}/config

Get the API token on https://www.flowdock.com/account/tokens

#{BASEDIR}/config should look roughly like this:

org: my-flowdock-org
token: b8227198b8ef6c57e2f55e34c3722706

END
    exit 2
  end
end
