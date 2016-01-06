require 'fileutils'
require 'logger'
require 'net/http'
require_relative 'ui'

# fdcli - a flowdock command line client
module FDCLI
  @basedir = "#{Dir.home}/.config/fdcli"
  @token = nil
  @org = nil
  @apiurl = nil
  @log = nil

  ### main

  def self.start(_options)
    init_config

    puts 'hello'
    @log.info 'hello world'

    #api_test_connection XXX XXX ENABLE AGAIN
    begin
      current_flow = nil
      p @basedir
      UI.init @log
    rescue StandardError => e
      puts e.message
      @log.fatal e
      exit 255
    end
  end

  def self.init_config
    FileUtils.mkdir_p @basedir
    f = File.open "#{@basedir}/fdcli.log", File::WRONLY | File::APPEND | File::CREAT
    f.sync = true
    f.truncate 0
    @log = Logger.new f
    h = {}
    begin
      File.open "#{@basedir}/config", 'r' do |file|
        file.each do |line|
          t = line.split(':')
          h[t[0]] = t[1].strip
        end
      end
      @token = h['token']
      @org = h['org']
      @apiurl = "https://#{@token}@api.flowdock.com"
    rescue
      fatal_token_error
    end
  end

  ### api

  def self.api_test_connection
    @log.info 'testing connection to flowdock'
    begin
      api_get "/organizations/#{@org}"
    rescue Exception => e
      @log.fatal e
      fatal_token_error
    end
  end

  def self.api_get(path)
    url = URI.parse "#{@apiurl}#{@path}"
    req = Net::HTTP::Get.new url.to_s
    res = Net::HTTP.start url.host, url.port { |http| http.request req }
  end

  ### utils

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
