require 'curses'
require 'terminfo'
require_relative 'utils'

include Curses

# fdcli ui
module UI
  @win = {}

  def self.make_windows
    clear
    refresh
    @win[:flows] = Window.new lines / 3 * 2, cols / 4, 0, 0
    @win[:chats] = Window.new lines / 3, cols / 4, lines / 3 * 2, 0
    @win[:main] = Window.new lines - 6, (cols / 4) * 3, 3, cols / 4
    @win[:main_info] = Window.new 3, (cols / 4) * 3, 0, cols / 4
    @win[:main_input] = Window.new 3, (cols / 4) * 3, lines - 3, cols / 4

    @win.each_value { |w| w.box '|', '-' } ## DEBUG
    @win[:main_info].setpos(0, 0)
    @win[:main_info].addstr("HELLO")
    @win.each_value { |w| w.refresh }
  end

  def self.init()
    init_screen
    at_exit do
      close_screen
    end

    make_windows

    loop do
      k = @win[:main].getch
      Utils.log.info k
      case k
      when KEY_RESIZE, KEY_REFRESH
        make_windows
      when ?q
        exit
      end
    end
  end

  def self.redraw
    @win.each_value { |w| w.refresh }
  end
end
