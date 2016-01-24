# api part of fdcli - Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require 'net/http'
require 'json'
require_relative 'utils'

module Api
  include Utils

  def self.test_connection
    Utils.log.info 'testing connection to flowdock'
    begin
      api_get "/organizations/#{ORG}"
    rescue StandardError => e
      Utils.log.fatal e
      Utils.fatal_token_error
    end
  end

  def self.get(path)
    url = URI.parse "#{APIURL}#{path}"
    Utils.log.info "GET #{path} (#{url}) "
    req = Net::HTTP::Get.new url
    res = Net::HTTP.start url.host, url.port, use_ssl: true do |http|
      req.basic_auth url.user, url.password
      res = http.request req
    end
    JSON.parse res.body
  end
end
