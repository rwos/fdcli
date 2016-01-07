# fdcli - a flowdock command line client
require_relative 'ui'
require_relative 'utils'
require_relative 'api'

module FDCLI
  def self.start(_options)
    puts 'hello'
    Utils.log.info 'hello world'
    Utils.init_config
    Api.test_connection
    Utils.log.info 'all good - starting'
    begin
      run
    rescue StandardError => e
      puts e.message
      Utils.log.fatal e
      exit 255
    end
  end

  def self.run
    current_flow = nil
    UI.running do |action|
      Utils.log.info "action: #{action}"
      case action
      when :quit
        exit
      end
    end
  end
end
