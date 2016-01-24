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
    #Api.test_connection ### XXX switch on again
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
        if (param_name.strip === current_flow)
          content = [:reverse, name, :endreverse]
        else
          content = [name]
        end
        FlowSelector.new content, hoverable: true, clickable: true, state: param_name
      }
      .unshift(UI::Element.new [''])
      .unshift(UI::Element.new [:underline, "Flows", :endunderline])

    UI.fill :main, main_content(current_flow)
    UI.fill :main_info,
      DB.from(:flows, 'parameterized_name', 'name', 'description')
      .select { |row| row.first === current_flow }
      .map { |row|
        param_name, name, description = row
        UI::Element.new [:underline, "#{name} (#{param_name})", :endunderline, "\n#{description}"]
      }
    ##### XXX XXX return to simple map
    #| DB.select('joined', 'name', 'parameterized_name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    #UI.fill :flows, DB.from(:flows) | DB.select('joined', 'name', 'parameterized_name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    #UI.fill :chats, DB.from(:private) | DB.select('open', 'name') | DB.where('True') | DB.fmt('(selectable %s)', 1)
    #UI.fill :main_input, 'huhuh'
    UI.running do |action, data|
      Utils.log.info "action: #{action} #{data}"
      case action
      when :scroll_up
        UI.scroll_main up: true
      when :scroll_down
        UI.scroll_main up: false
      when :quit
        exit
      when :hover
        case data
        when FlowSelector
          display_help "Switch to #{data.text[0]} (#{data.state})"
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

  def self.main_content(current_flow)
    ### XXX TODO scrolling: if we're at the top of the pad, put new data into it
    ###          - maybe implement as an event, too
    nicks = {}
    DB.from(:users, 'id', 'nick').map { |row| nicks[row[0]] = row[1] }

    start_day = nil;
    last_poster = nil;
    DB.from_messages(current_flow, 'event', 'thread_id', 'sent', 'user', 'content')
    .reverse
    .select { |row| row.first === 'message' }
    .flat_map { |row|
      _, thread_id, timestamp, user_id, content = row
      content = '' if content.nil?
      nick = nicks.fetch user_id, 'unknown user'
      sent = Time.at(timestamp.to_i / 1000).strftime '%H:%M'
      day = Time.at(timestamp.to_i / 1000).strftime '%F'

      out = []
      ##### TODO: make new element that renders with a prefix (so word-wrapping content doesn't destroy the left side)
      start_day = day if start_day.nil?
      if day != start_day
        out.push(UI::Element.new ["     ┌────────────────────────────────── #{day}"])
      end
      prefix = '     │    '
      if nick == last_poster && day == start_day ### TODO: also check thread (different threads should show nick again)
        out.push(UI::Element.new ["#{sent}┤ └─ ", content], wrap_prefix: prefix)
      else
        last_poster = nick
        out.push(UI::Element.new ["#{sent}┤ ", :bold, nick, :endbold, " ", content], wrap_prefix: prefix)
      end
      start_day = day
      out
    }
  end

  def self.display_help(msg)
    UI.fill :main_input, [UI::Element.new([msg])]
  end
end
