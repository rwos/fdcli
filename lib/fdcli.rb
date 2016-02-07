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
      update_aux
      _, first_flow = DB.from(:flows, 'joined', 'parameterized_name')
        .select { |row| row.first === 'true' }
        .first
      run first_flow
    rescue StandardError => e
      puts e.message
      Utils.log.fatal e
      exit 255
    end
  end

  class FlowSelector < UI::Element
  end

  class PrivateChatSelector < UI::Element
  end

  def self.update_aux
    #DB.into :users, Api.get("/organizations/#{Utils::ORG}/users"), 'id', 'nick', 'name', 'email'
    #DB.into :flows, Api.get('/flows/all'), 'id', 'parameterized_name', 'name', 'description', 'joined'
    #DB.into :private, Api.get('/private'), 'id', 'name', 'open'
    #### XXX TODO: since_id handling
    flow = 'scholar-dev-panic'
    DB.add_to_messages flow, Api.get("/flows/#{Utils::ORG}/#{flow}/messages?limit=100"), 'id', 'sent', 'event', 'thread_id', 'user', 'tags', 'content'
  end

    #### XXX XXX TODO
  #def self.update_flow(flow, mode)
    #DB.add_to_messages flow
  #  case mode
  #  when :above_top
  #    #since_id = ... ? or until_id?
  #  when :below_bottom
  #    #since_id = ... ? or until_id?
  #  end
  #  # api_get "/flows/$ORG/$flow_name/messages?limit=100&since_id=$since_id" | json_to_db id sent event thread_id user tags content | db_store_messages ${flow_name}
  #  #  api_get /flows/$ORG/$flow_name/messages?limit=100 | json_to_db id sent event thread_id user tags content | db_store_messages ${flow_name}
  #end

  def self.run(current_flow, is_private: false)

    UI.fill :flows,
      DB.from(:flows, 'joined', 'name', 'parameterized_name')
      .select { |row| row.first === 'true' }
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

    UI.fill :chats,
      DB.from(:private, 'open', 'name')
      .select { |row| row.first === 'true' }
      .map { |row|
        _, name = row
        PrivateChatSelector.new [name], hoverable: true, clickable: true, state: name
      }
      .unshift(UI::Element.new [''])
      .unshift(UI::Element.new [:underline, "Private", :endunderline])

    UI.fill :main, main_content(current_flow, is_private)
    UI.fill :main_info,
      DB.from(:flows, 'parameterized_name', 'name', 'description')
      .select { |row| row.first === current_flow }
      .map { |row|
        param_name, name, description = row
        description = '' if description == 'NULL'
        UI::Element.new [:underline, "#{name} (#{param_name})", :endunderline, "\n#{description}"]
      }
    ##### XXX XXX return to simple map
    #UI.fill :main_input, 'huhuh'
    UI.running do |action, data|
      Utils.log.info "action: #{action} #{data}"
      case action
      when :quit
        exit
      when :hover
        case data
        when FlowSelector
          display_help "Switch to #{data.text[0]} (#{data.state})"
        when PrivateChatSelector
          display_help "Switch to private chat with #{data.state}"
        end
      when :unhover
        display_help ''
      when :click
        case data
        when FlowSelector
          run data.state
        when PrivateChatSelector
          run data.state, is_private: true
        end
      end
    end
  end

  def self.main_content(current_flow, is_private)
    ### XXX TODO scrolling: if we're at the top of the pad, put new data into it
    ###          - maybe implement as an event, too
    nicks = {}
    DB.from(:users, 'id', 'nick').map { |row| nicks[row[0]] = row[1] }

    start_day = nil;
    last_poster = nil;
    last_thread = nil;
    DB.from_messages(current_flow, 'event', 'thread_id', 'sent', 'user', 'content')
    .reverse
    .select { |row| row.first === 'message' }
    .flat_map { |row|
      _, thread_id, timestamp, user_id, content = row
      content = '' if content.nil?
      nick = nicks.fetch user_id, 'unknown user'
      sent = Time.at(timestamp.to_i / 1000).strftime '%H:%M'
      day = Time.at(timestamp.to_i / 1000).strftime '%F'

      #### XXX this isn't final
      thread = ''
      #markers = '▖▗▘▙▚▛▜▞▟░▒▓█'
      thread_num = 0
      thread_id[-4..-1].each_char do |c|
        thread_num += c.ord
      end
      thread_length = 8
      thread_start = thread_num % thread_length
      thread_start_marker  = (' ' * thread_start) + '┌┐' + (' ' * (thread_length - thread_start))
      thread_normal_marker = (' ' * thread_start) + '││' + (' ' * (thread_length - thread_start))
      thread =  (thread_id == last_thread && day == start_day ? thread_normal_marker : thread_start_marker)

      out = []
      start_day = day if start_day.nil?
      if thread_id != last_thread && !last_thread.nil? || (day != start_day)
        # thread end marker XXX cleanup
        thread_num = 0
        last_thread[-4..-1].each_char do |c|
          thread_num += c.ord
        end
        thread_start = thread_num % thread_length
        end_thread = (' ' * thread_start) + '└' + '┘' + (' ' * (thread_length - thread_start)) + '      │'
        out.push(UI::Element.new ["#{end_thread}"])
      end
      if day != start_day
        out.push(UI::Element.new ["#{day} ─────┐"])
      end
      prefix = "#{thread_normal_marker}      │    "
      if nick == last_poster && day == start_day && thread_id == last_thread
        out.push(UI::Element.new [thread, " #{sent}┤ └─ ", content], wrap_prefix: prefix)
      else
        out.push(UI::Element.new [thread, " #{sent}┤ ", :bold, nick, :endbold, " ", content], wrap_prefix: prefix)
      end
      start_day = day
      last_poster = nick
      last_thread = thread_id
      out
    }
  end

  def self.display_help(msg)
    UI.fill :main_input, [UI::Element.new([msg])]
  end
end
