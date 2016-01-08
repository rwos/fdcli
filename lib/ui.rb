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

    @win.each do |k, w|
      @content[k] = [] unless @content.has_key? k
      fill(k, @content[k])
    end
  end

  def self.fill(name, elements)
    w = @win[name]
    ### FIXME: w.clear should do this but somehow redraws the whole screen
    ###        (all windows) which looks shit
    for y in (w.begy..(w.begy+w.maxy))
      w.setpos y, 0
      w.clrtoeol
    end
    w.setpos 0, 0
    w.box '|', '-' ### XXX DEBUG
    @content[name] = elements
    elements.map! do |e|
      ### Current assumption: elements are blocks (there's always only
      ### one element on a line; elements can span multiple lines)
      e.pos = {
        xstart: w.curx + w.begx,
        ystart: w.cury + w.begy,
        xend: [e.text.length + w.begx, w.begx + w.maxx].min,
      }
      ### XXX styles should live inside Element
      case e.style
      when :selected
        w.attron(A_STANDOUT)
        w.addstr e.text
        w.attroff(A_STANDOUT)
      else
        w.addstr e.text
      end
      e.pos[:yend] = w.cury + w.begy
      w.addstr "\n"
      e
    end
    w.refresh
  end

  def self.init(unhover)
    @unhover = unhover
    init_screen
    noecho
    curs_set 0
    raw
    #start_color
    stdscr.keypad true
    crmode
    mousemask BUTTON1_CLICKED | REPORT_MOUSE_POSITION
    at_exit do
      close_screen
    end
    make_windows
  end

  def self.running
    loop do
      k = getch
      case k
      when KEY_RESIZE, KEY_REFRESH
        make_windows
      when KEY_MOUSE
        m = getmouse
        next if m.nil?
        case m.bstate
        when BUTTON1_CLICKED, BUTTON1_PRESSED, BUTTON1_DOUBLE_CLICKED
          fire_click m.x, m.y
        else
          fire_hover m.x, m.y
        end
      when 'q'
        yield :quit
      else
        yield :unknown
      end
    end
  end

  def self.find_element(x, y)
    @content.values.flatten.find { |e|
      e.pos[:ystart] <= y && e.pos[:yend] >= y &&
      e.pos[:xstart] <= x && e.pos[:xend] >= x
    }
  end

  def self.fire_click(x, y)
    e = find_element x, y
    Utils.log.info "CLICK: #{[x, y]} - #{e}"
    e.click.call unless e.nil? || e.click.nil?
  end

  def self.fire_hover(x, y)
    e = find_element x, y
    if e.nil? || e.hover.nil?
      @unhover.call
    else
      e.hover.call
    end
  end

  class Element
    attr_accessor :pos
    attr_reader :text, :hover, :click, :style
    def initialize(text, hover: nil, click: nil, style: nil)
      @text = text
      @hover = hover
      @click = click
      @style = style
    end
  end
end
