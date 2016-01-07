# fdcli - a flowdock command line client
# Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require_relative 'ui'
require_relative 'utils'
require_relative 'api'
require_relative 'db'

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
    current_flow = 'berlin'

    UI.init
    UI.fill :flows, DB.from(:flows) | DB.select('joined', 'name', 'parameterized_name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    UI.fill :chats, DB.from(:private) | DB.select('open', 'name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    UI.fill :main_info, DB.from(:flows) | DB.select('parameterized_name', 'name', 'description') | DB.where(current_flow) | DB.fmt("(selected %s)\n%s", 1, 2)
    UI.fill :main_input, 'huhuh'
    UI.fill :main, DB.from_messages(current_flow) | DB.select('event', 'thread_id', 'sent', 'user', 'content') | DB.reverse | DB.where('message') | DB.fmt
    UI.running do |action|
      Utils.log.info "action: #{action}"
      case action
      when :quit
        exit
      end
    end
  end
end
