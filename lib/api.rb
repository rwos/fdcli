# api part of fdcli - Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require 'net/http'
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

  def self.api_get(path)
    url = URI.parse "#{APIURL}#{path}"
    req = Net::HTTP::Get.new url.to_s
    res = Net::HTTP.start url.host, url.port { |http| http.request req }
  end
end
