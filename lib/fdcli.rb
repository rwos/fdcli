require_relative 'ui'
require_relative 'utils'
require_relative 'api'


# fdcli - a flowdock command line client
module FDCLI

  ### main

  def self.start(_options)
    puts 'hello'
    Utils.log.info 'hello world'
    Utils.init_config
    Api.test_connection
    Utils.log.info 'all good - starting'

    begin
      current_flow = nil
      p @basedir
      UI.init
    rescue StandardError => e
      puts e.message
      Utils.log.fatal e
      exit 255
    end
  end
end
