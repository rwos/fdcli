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
    ### XXX move windows into main app
    # R = Rational
    # windows = [
    #   # vertical divisions ### XXX SHOULD BE VBOX
    #   {'25%' => :left, 1 => :EMPTY, :rest => :right},
    #   # horizontal divisions XXX SHOULD BE HBOX
    #   {
    #     left: {
    #       '50%' => :flows,
    #       1 => :EMPTY,
    #       :rest => :chats
    #     },
    #     right: {
    #       2 => :main_info,
    #       1 => :EMPTY,
    #       :rest => :main,
    #       1 => :EMPTY,
    #       2 => :main_input,
    #     }
    #     main: { ### XXX SHOULD BE VBOX
    #       # now vertical divisions again
    #       5 => :main_lefthand,
    #       :rest => :main_content,
    #     }
    #   }
    # ]
    #
    # scrolling? and especially linked scrolling... (main_lefthand + main_content)
    # ===> for that the whole VBOX has to be a PAD ===> it scrolls inside the hbox
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
    @content[name] = elements
    elements.map! do |e|
      ### XXX
      ### Current assumption: elements are blocks (there's always only
      ### one element on a line; elements can span multiple lines)
      e.pos = {
        xstart: w.curx + w.begx,
        ystart: w.cury + w.begy,
        xend: w.begx + w.maxx,
      }
      ### XXX styles should live inside Element
      e.render(w)
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
    attr_reader :text, :hoverable, :clickable, :state
    def initialize(text, hoverable: false, clickable: false, state: nil, wrap_prefix: '')
      @text = text
      @hoverable = hoverable
      @clickable = clickable
      @state = state
      @wrap_prefix = wrap_prefix
    end
    def render(w)
      map = {
        bold: A_BOLD,
        reverse: A_STANDOUT,
        underline: A_UNDERLINE,
      }
      ##### XXX TODO: Element is more like a <div>, and these should be <span>s (including hover + click and shit)
      line_sz = w.maxx - 1
      line_left = line_sz
      @text.each do |part|
        if part.is_a? Symbol
          if part =~ /^end/
            key = part.to_s.sub(/^end/, '').to_sym
            Utils.log.fatal "unknown end style #{part} (#{key})" if map[key].nil?
            w.attroff map[key]
          else
            Utils.log.fatal "unknown style #{part}" if map[part].nil?
            w.attron map[part]
          end
        else
          part.each_char do |c|
            if line_left < 1 || c === "\n"
              w.addstr "\n"
              line_left = line_sz
              w.addstr @wrap_prefix
              line_left -= @wrap_prefix.length
              unless c =~ /\s/
                w.addstr c
                line_left -= c.length
              end
            else
              w.addstr c
              line_left -= c.length
            end
          end
          ##### XXX this is better, but breaks real linebreaks and things starting with whitespace
          #words.each do |word|
          #  if word.length < line_left
          #    w.addstr word
          #    w.addstr ' '
          #    line_left -= (word.length + 1)
          #  elsif word.length <= line_sz
          #    # word doesn't fit on this line, but it _does_ fit on one line
          #    w.addstr "\n"
          #    line_left = line_sz
          #    w.addstr @wrap_prefix
          #    line_left -= @wrap_prefix.length
          #    w.addstr word
          #    w.addstr ' ' if word.length < line_sz
          #    line_left -= (word.length + 1)
          #  else
          #    # hard-wrap
          #    ### XXX use from above
          #end
        end
      end
    end
  end
end
