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
    UI.init
    begin
      run 'berlin' ###### XXX XXX XXX
    rescue StandardError => e
      puts e.message
      Utils.log.fatal e
      exit 255
    end
  end

  class FlowSelector < UI::Element
  end

  def self.run(current_flow)
    UI.fill :flows,
      DB.from(:flows, 'joined', 'name', 'parameterized_name')
      .select { |row| row.first === 'True' }
      .map { |row|
        _, name, param_name = row
        style = :selectable
        style = :selected if (param_name.strip === current_flow)
        FlowSelector.new(name, style: style, hoverable: true, clickable: true, state: param_name)
      }
    UI.fill :main,
      DB.from_messages(current_flow, 'event', 'thread_id', 'sent', 'user', 'content')
      .take(100) ## XXX scrolling....
      .reverse
      .select { |row| row.first === 'message' }
      .map { |row|
        _, _, _, user, content = row
        content = '' if content.nil?
        UI::Element.new user + ": " + content
      }
    ##### XXX XXX return to simple map
    #| DB.select('joined', 'name', 'parameterized_name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    #UI.fill :flows, DB.from(:flows) | DB.select('joined', 'name', 'parameterized_name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    #UI.fill :chats, DB.from(:private) | DB.select('open', 'name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    #UI.fill :main_info, DB.from(:flows) | DB.select('parameterized_name', 'name', 'description') | DB.where(current_flow) | DB.fmt("(selected %s)\n%s", 1, 2)
    #UI.fill :main_input, 'huhuh'
    UI.running do |action, data|
      Utils.log.info "action: #{action} #{data}"
      case action
      when :quit
        exit
      when :hover
        case data
        when FlowSelector
          display_help "Switch to #{data.text} (#{data.state})"
        end
      when :unhover
        display_help ''
      when :click
        case data
        when FlowSelector
          run data.state
        end
      end
    end
  end

  def self.display_help(msg)
    UI.fill :main_input, [UI::Element.new(msg)]
  end
end
