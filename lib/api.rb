require 'net/http'
require_relative 'utils'


module Api
include Utils
  def self.test_connection
    p @@org
    Utils.log.info 'testing connection to flowdock'
    begin
      api_get "/organizations/#{@@org}"
    rescue Exception => e
      Utils.log.fatal e
      Utils.fatal_token_error
    end
  end

  def self.api_get(path)
    url = URI.parse "#{@@apiurl}#{path}"
    req = Net::HTTP::Get.new url.to_s
    res = Net::HTTP.start url.host, url.port { |http| http.request req }
  end
end
