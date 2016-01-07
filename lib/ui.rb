# user interface part of fdcli - Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require 'curses'
require 'terminfo'
require_relative 'utils'

include Curses

# fdcli ui
module UI
  @win = {}
  @content = {}

  def self.make_windows
    clear
    refresh
    @win[:flows] = Window.new lines / 3 * 2, cols / 4, 0, 0
    @win[:chats] = Window.new lines / 3, cols / 4, lines / 3 * 2, 0
    @win[:main] = Window.new lines - 6, (cols / 4) * 3, 3, cols / 4
    @win[:main_info] = Window.new 3, (cols / 4) * 3, 0, cols / 4
    @win[:main_input] = Window.new 3, (cols / 4) * 3, lines - 3, cols / 4

    @win.each_value { |w| w.box '|', '-' } ## DEBUG
    @win.each do |k, w|
      w.setpos 0, 0
      @content[k] = '' unless @content.has_key? k
      w.addstr(@content[k])
      w.refresh
    end
  end

  def self.fill(name, elements)
    elements.map do |e|
      @content[name] << e.text
      @win[name].addstr e.text
      @win[name].refresh
    end
  end

  def self.init
    init_screen
    noecho
    raw
    #start_color
    stdscr.keypad true
    crmode
    mousemask ALL_MOUSE_EVENTS | REPORT_MOUSE_POSITION
    at_exit do
      close_screen
    end
    make_windows
    Utils.log.info(Curses.ESCDELAY())
  end

  def self.running
    loop do
      k = getch
      Utils.log.info "K=#{k}"
      case k
      when KEY_RESIZE, KEY_REFRESH
        make_windows
      when KEY_MOUSE
        Utils.log.info "MOUSE KEY"
        m = getmouse
        Utils.log.info "MOUSE: #{[m.x, m.y, m.bstate]} | KEY: #{k}"
      when 'q'
        yield :quit
      else
        yield :unknown
      end
    end
  end

  class Element
    attr_reader :text, :hover, :click, :style
    def initialize(text, hover: nil, click: nil, style: nil)
      @text = text
      @hover = hover
      @click = click
      @style = style
    end
  end
end
