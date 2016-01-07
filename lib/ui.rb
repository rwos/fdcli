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

  def self.fill(name, value)
    @content[name] << value
    @win[name].addstr(value)
    @win[name].refresh
  end

  def self.init
    init_screen
    at_exit do
      close_screen
    end
    make_windows
  end

  def self.running
    loop do
      k = @win[:main].getch
      case k
      when KEY_RESIZE, KEY_REFRESH
        make_windows
        next
      when 'q'
        yield :quit
      else
        yield :unknown
      end
    end
  end
end
