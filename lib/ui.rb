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
  @currently_hovered = nil
  @current_main_scroll = 0

  def self.make_windows
    clear
    refresh
    @win[:flows] = Window.new lines / 3 * 2, cols / 4, 0, 0
    @win[:chats] = Window.new lines / 3, cols / 4, lines / 3 * 2, 0
    @win[:main_window] = Window.new lines - 7, (cols / 4) * 3, 3, cols / 4
    @win[:main] = Pad.new 1000, (cols / 4) * 3 #### XXX pad height should probably come from somewhere?
    @win[:main_info] = Window.new 2, (cols / 4) * 3, 0, cols / 4
    @win[:main_input] = Window.new 2, (cols / 4) * 3, lines - 2, cols / 4

    @win.each do |k, w|
      @content[k] = [] unless @content.has_key? k
      fill(k, @content[k])
    end
  end

  # returns the elements that actually made it onto the screen
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
      ### XXX
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
    if w.is_a? Pad #### XXX this looks more general than it is, only works for :main
      # paint pad into main window
      wm = @win[:main_window]
      # reset scroll position so that the last line is visible
      @current_main_scroll = w.cury - (wm.maxy - wm.begy)
      w.refresh @current_main_scroll, 0, wm.begy, wm.begx, wm.begy + wm.maxy, wm.begx + wm.maxx
    else
      w.refresh
    end
  end

  def self.scroll_main(up: true)
    @current_main_scroll += up ? -1 : 1
    @current_main_scroll = 0 if @current_main_scroll < 0
    w = @win[:main]
    wm = @win[:main_window]
    w.refresh @current_main_scroll, 0, wm.begy, wm.begx, wm.begy + wm.maxy, wm.begx + wm.maxx
  end

  def self.init()
    init_screen
    noecho
    curs_set 0
    raw
    #start_color
    stdscr.keypad true
    crmode
    mousemask BUTTON1_CLICKED | REPORT_MOUSE_POSITION | ALL_MOUSE_EVENTS
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
          hit = fire_click(m.x, m.y)
          yield :click, hit if hit
        when BUTTON4_PRESSED
          yield :scroll_up
        when REPORT_MOUSE_POSITION
          ### XXX hack - scroll down only seems to report mouse position
          if @current_mouse_position == [m.x, m.y]
            yield :scroll_down
          else
            was_hover = false
            fire_hover(m.x, m.y).each do |hit|
              was_hover = true
              yield *hit
            end
            unless was_hover
              yield :unknown_mouse, [k, m, m.bstate, m.x, m.y, @current_mouse_position]
            end
          end
          @current_mouse_position = [m.x, m.y]
        end
      when 'q'
        yield :quit
      when 'k'
        yield :scroll_up
      when 'j'
        yield :scroll_down
      else
        yield :unknown, k
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
    e if !e.nil? && e.clickable
  end

  def self.fire_hover(x, y)
    e = find_element x, y
    events = []
    if e != @currently_hovered
      if !@currently_hovered.nil? && @currently_hovered.hoverable
        events.push [:unhover, @currently_hovered]
      end
      @currently_hovered = e
      events.push [:hover, e] if !e.nil? && e.hoverable
    end
    events
  end

  class Element
    attr_accessor :pos
    attr_reader :text, :hoverable, :clickable, :style, :state
    def initialize(text, hoverable: false, clickable: false, style: nil, state: nil)
      @text = text
      @hoverable = hoverable
      @clickable = clickable
      @style = style
      @state = state
    end
  end
end
