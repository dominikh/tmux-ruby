# -*- coding: utf-8 -*-
require "tmux/window/status"

module Tmux
  # A {Window window} occupies the entire
  # screen and may be split into rectangular {Pane panes}, each of
  # which is a separate pseudo terminal (the pty(4) manual page
  # documents the technical details of pseudo terminals).
  #
  # @todo Figure out better names for some attributes, e.g. mode_mouse
  class Window
    include Comparable

    class << self
      # @return [OptionsList]
      attr_reader :options
      undef_method "options"
      def options(server)
        OptionsList.new(:window, server, true)
      end
    end

    # @overload number
    #   @return [Number]
    # @overload number=(new_number)
    #   @return [Number]
    #   @raise [Exception::IndexInUse]
    #   @see #move
    # @return [Number]
    attr_accessor :number
    undef_method "number="

    # @overload session
    #   @return [Session]
    # @overload session=(new_session)
    #   Moves the window to another {Session session}. First it tries
    #   to reuse the current number of the window. If that number is
    #   already used in the new {Session session}, the first free
    #   number will be used instead.
    #
    #   @return [Session]
    #   @raise [Exception::IndexInUse]
    #   @see #move
    #   @todo use base-index
    # @return [Session]
    attr_accessor :session
    undef_method "session="
    # @return [OptionsList]
    attr_reader :options
    # @return [Status]
    attr_reader :status
    def initialize(session, number)
      @session, @number = session, number
      @options = OptionsList.new(:window, self, false)
      @status = Status.new(self)
    end

    def session=(new_session)
      i = -1
      first_try = true
      begin
        num = (first_try ? @number : (i += 1))
        move(new_session, num)
      rescue IndexInUse
        first_try = false
        retry
      end
    end

    def number=(new_number)
      move(@session, new_number)
    end

    # Moves the window to either a different session, a different
    # position or both.
    #
    # @param [Session] new_session
    # @param [Number] new_number
    #
    # @return [void]
    # @raise [Exception::IndexInUse]
    # @see #number=
    # @see #session=
    #
    # @tmux move-window
    def move(new_session, new_number)
      return if @session == new_session && @number == new_number
      target = "%s:%s" % [new_session.identifier, new_number]

      res = server.invoke_command("move-window -s #{identifier} -t #{target}")
      if res =~ /^can't move window: index in use: \d+/
        raise IndexInUse, [new_session, new_number]
      end
      @session = new_session
      @number  = new_number
    end

    def <=>(other)
      return nil unless other.is_a?(Window)
      [@session, @number] <=> [other.session, other.number]
    end

    # @return [Boolean]
    def ==(other)
      self.class == other.class && @session == other.session && @number == other.number
    end

    # @return [Number]
    def hash
      [@session.hash, @number].hash
    end

    # @return [Boolean]
    def eql?(other)
      self == other
    end

    # @return [Server]
    attr_reader :server
    undef_method "server"
    def server
      @session.server
    end

    # @return [String]
    # @tmuxver &gt;=1.1
    # @tmux rename-window
    attr_accessor :name
    undef_method "name"
    undef_method "name="
    def name
      server.check_for_version!("1.1")

      @session.windows_information[@number][:name]
    end

    def name=(value)
      # TODO escape name?
      server.invoke_command "rename-window -t #{identifier} '#{value}'"
    end

    # @return [Integer]
    # @tmuxver &gt;=1.1
    attr_reader :width
    undef_method "width"
    def width
      server.check_for_version!("1.1")

      @session.windows_information[@number][:width]
    end

    # @return [Integer]
    # @tmuxver &gt;=1.1
    attr_reader :height
    undef_method "height"
    def height
      server.check_for_version!("1.1")

      @session.windows_information[@number][:height]
    end

    # @return [String]
    attr_reader :identifier
    undef_method "identifier"
    def identifier
      "%s:%s" % [@session.identifier, @number]
    end

    # Aggressively resize the window. This means that tmux will resize
    # the window to the size of the smallest {Session session} for
    # which it is the current window, rather than the smallest
    # {Session session} to which it is attached. The window may resize
    # when the current window is changed on another {Session session};
    # this option is good for full-screen programs which support
    # SIGWINCH and poor for interactive programs such as shells.
    #
    # @return [Boolean]
    attr_accessor :aggressive_resize
    undef_method "aggressive_resize"
    undef_method "aggressive_resize="
    def aggressive_resize
      @options.aggressive_resize
    end
    alias_method :aggressive_resize?, :aggressive_resize

    def aggressive_resize=(bool)
      @options.aggressive_resize = bool
    end

    # Control automatic window renaming. When this setting is enabled,
    # tmux will attempt – on supported platforms – to rename the
    # window to reflect the command currently running in it. This flag
    # is automatically disabled for an individual window when a name
    # is specified at creation with {Session#create_window} or
    # {Server#create_session}, or later with {#name=}.
    #
    # @return [Boolean]
    attr_accessor :automatic_rename
    undef_method "automatic_rename"
    undef_method "automatic_rename="
    def automatic_rename
      @options.automatic_rename
    end
    alias_method :automatic_rename?, :automatic_rename

    def automatic_rename=(bool)
      @options.automatic_rename = bool
    end

    # Duplicate input to any {Pane pane} to all other {Pane panes} in
    # the same window (only for {Pane panes} that are not in any
    # special mode)
    #
    # @return [Boolean]
    attr_accessor :synchronize_panes
    undef_method "synchronize_panes"
    undef_method "synchronize_panes="
    def synchronize_panes
      @options.synchronize_panes
    end
    alias_method :synchronize_panes?, :synchronize_panes

    def synchronize_panes=(bool)
      @options.synchronize_panes = bool
    end

    # A window with this flag set is not destroyed when the program
    # running in it exits. The window may be reactivated with
    # {#respawn}.
    #
    # @return [Boolean]
    attr_accessor :remain_on_exit
    undef_method "remain_on_exit"
    undef_method "remain_on_exit="
    def remain_on_exit
      @options.remain_on_exit
    end
    alias_method :remain_on_exit?, :remain_on_exit

    def remain_on_exit=(bool)
      @options.remain_on_exit = bool
    end

    # Instructs tmux to expect UTF-8 sequences to appear in this
    # window.
    #
    # @return [Boolean]
    attr_accessor :utf8
    undef_method "utf8"
    undef_method "utf8="
    def utf8
      @options.utf8
    end
    alias_method :utf8?, :utf8

    def utf8=(bool)
      @options.utf8 = bool
    end

    # Monitor for activity in the window. Windows with activity are
    # highlighted in the {StatusBar status line}.
    #
    # @return [Boolean]
    attr_accessor :monitor_activity
    undef_method "monitor_activity"
    undef_method "monitor_activity="
    def monitor_activity
      @options.monitor_activity
    end
    alias_method :monitor_activity?, :monitor_activity

    def monitor_activity=(bool)
      @options.monitor_activity = bool
    end

    # Monitor content in the window. When the
    # {http://linux.die.net/man/3/fnmatch fnmatch(3)} pattern appears
    # in the window, it is highlighted in the {StatusBar status line}.
    #
    # @return [String]
    attr_accessor :monitor_content
    undef_method "monitor_content"
    undef_method "monitor_content="
    def monitor_content
      @options.monitor_content
    end

    def monitor_content=(pattern)
      @options.monitor_content = pattern
    end

    # Prevent tmux from resizing the window to greater than
    # `max_width`. A value of zero restores the default unlimited
    # setting.
    #
    # @return [Number]
    attr_accessor :max_width
    undef_method "max_width"
    undef_method "max_width="
    def max_width
      @options.force_width
    end

    def max_width=(value)
      @options.force_width = value
    end
    alias_method :force_width, :max_width
    alias_method :force_width=, "max_width="

    # Prevent tmux from resizing the window to greater than
    # `max_height`. A value of zero restores the default unlimited
    # setting.
    #
    # @return [Number]
    attr_accessor :max_height
    undef_method "max_height"
    undef_method "max_height="
    def max_height
      @options.force_height
    end

    def max_height=(value)
      @options.force_height = value
    end
    alias_method :force_height, :max_height
    alias_method :force_height=, "max_height="

    # If this option is set to true, tmux will generate
    # {http://linux.die.net/man/1/xterm xterm(1)}-style function key
    # sequences. These have a number included to indicate modifiers
    # such as Shift, Alt or Ctrl. The default is false.
    #
    # @return [Boolean]
    attr_accessor :xterm_keys
    undef_method "xterm_keys"
    undef_method "xterm_keys="
    def xterm_keys
      @options.xterm_keys
    end
    alias_method :xterm_keys?, :xterm_keys

    def xterm_keys=(bool)
      @options.xterm_keys = bool
    end

    # Sets the window's conception of what characters are considered
    # word separators, for the purposes of the next and previous word
    # commands in {Pane#copy_mode copy mode}. The default is `[" ",
    # "-", "_", "@"]`.
    #
    # @return [Array<String>]
    attr_accessor :word_separators
    undef_method "word_separators"
    undef_method "word_separators="
    def word_separators
      @options.word_separators
    end

    def word_separators=(value)
      @options.word_separators = value
    end

    # This option configures whether programs running inside tmux may
    # use the terminal alternate screen feature, which allows the
    # smcup and rmcup {http://linux.die.net/man/5/terminfo
    # terminfo(5)} capabilities to be issued to preserve the existing
    # window content on start and restore it on exit.
    #
    # @return [Boolean]
    attr_accessor :alternate_screen
    undef_method "alternate_screen"
    undef_method "alternate_screen="
    def alternate_screen
      @options.alternate_screen
    end
    alias_method :alternate_screen?, :alternate_screen

    def alternate_screen=(bool)
      @options.alternate_screen = bool
    end

    # Mouse state in modes. If true, the mouse may be used to copy a
    # selection by dragging in {Pane#copy_mode copy mode}, or to
    # select an option in choice mode.
    #
    # @return [Boolean]
    attr_accessor :mode_mouse
    undef_method "mode_mouse"
    undef_method "mode_mouse="
    def mode_mouse
      @options.mode_mouse
    end
    alias_method :mode_mouse?, :mode_mouse

    def mode_mouse=(bool)
      @options.mode_mouse = bool
    end

    # Clock color.
    #
    # @return [Symbol]
    attr_accessor :clock_mode_color
    undef_method "clock_mode_color"
    undef_method "clock_mode_color="
    def clock_mode_color
      @options.clock_mode_colour
    end
    alias_method :clock_mode_colour, :clock_mode_color

    def clock_mode_color=(color)
      @options.clock_mode_colour = color
    end
    alias_method :clock_mode_colour=, "clock_mode_color="

    # Clock hour format.
    #
    # @return [Symbol<:twelve, :twenty_four>]
    attr_accessor :clock_mode_style
    undef_method "clock_mode_style"
    undef_method "clock_mode_style="

    def clock_mode_style
      @options.clock_mode_style
    end

    def clock_mode_style=(style)
      @options.clock_mode_style = style
    end

    # Set the height of the main (left or top) pane in the
    # main-horizontal or main-vertical {#layout= layouts}.
    #
    # @return [Number]
    # @see #layout=
    attr_accessor :main_pane_height
    undef_method "main_pane_height"
    undef_method "main_pane_height="
    def main_pane_height
      @options.main_pane_height
    end

    def main_pane_height=(height)
      @options.main_pane_height = height
    end

    # Set the width of the main (left or top) pane in the
    # main-horizontal or main-vertical {#layout= layouts}.
    #
    # @return [Number]
    # @see #layout=
    attr_accessor :main_pane_width
    undef_method "main_pane_width"
    undef_method "main_pane_width="
    def main_pane_width
      @options.main_pane_width
    end

    def main_pane_width=(width)
      @options.main_pane_width = width
    end

    # @return [Symbol]
    attr_accessor :mode_attr
    undef_method "mode_attr"
    undef_method "mode_attr="
    def mode_attr
      @options.mode_attr
    end

    def mode_attr=(attr)
      @options.mode_attr = attr
    end

    # @return [Symbol]
    attr_accessor :mode_bg
    undef_method "mode_bg"
    undef_method "mode_bg="
    def mode_bg
      @options.mode_bg
    end

    def mode_bg=(bg)
      @options.mode_bg = bg
    end

    # @return [Symbol]
    attr_accessor :mode_fg
    undef_method "mode_fg"
    undef_method "mode_fg="
    def mode_fg
      @options.mode_fg
    end

    def mode_fg=(fg)
      @options.mode_fg = fg
    end

    # @return [Symbol]
    attr_accessor :mode_keys
    undef_method "mode_keys"
    undef_method "mode_keys="
    def mode_keys
      @options.mode_keys
    end

    def mode_keys=(keymap)
      @options.mode_keys = keymap
    end

    # Kills the window.
    # @tmux kill-window
    # @return [void]
    def kill
      server.invoke_command "kill-window -t #{identifier}"
    end

    # Rotates the positions of the {Pane panes} within a window.
    #
    # @tmux rotate-window
    # @return [void]
    def rotate(direction = :upward)
      flag = case direction
             when :upward
               "U"
             when :downward
               "D"
             else
               raise ArgumentError
             end
      server.invoke_command "rotate-window -#{flag} -t #{identifier}"
    end

    # @todo attr_reader
    # @param [Symbol<:even_horizontal, :even_vertical, :main_horizontal, :main_vertical] The layout to apply to the window
    # @return [Symbol]
    # @tmux select-layout
    # @tmuxver &gt;=1.3 for :tiled layout
    # @tmuxver &gt;=1.0 for all other layouts
    attr_writer :layout
    undef_method "layout="
    def layout=(layout)
      server.check_for_version!("1.0")
      raise Exception::UnsupportedVersion, "1.3" if layout == :tiled && server.version < "1.3"

      valid_layouts = [:even_horizontal, :even_vertical, :main_horizontal, :main_vertical, :tiled]
      raise ArgumentError unless valid_layouts.include?(layout)
      layout = layout.to_s.tr("_", "-")
      server.invoke_command "select-layout -t #{identifier} #{layout}"
    end

    # @param [Hash] search Filters the resulting hash using {FilterableHash#filter}
    # @return [Hash] A hash with information for all panes
    # @tmux list-panes
    # @tmuxver &gt;=1.1
    def panes_information(search={})
      server.check_for_version!("1.1")

      hash = {}
      output = server.invoke_command "list-panes -t #{identifier}"
      output.each_line do |pane|
        params = pane.match(/^(?<num>\d+): \[(?<width>\d+)x(?<height>\d+)\] \[history (?<cur_history>\d+)\/(?<max_history>\d+), (?<memory>\d+) bytes\](?<active> \(active\))?$/)
        num = params[:num].to_i
        width = params[:width].to_i
        height = params[:height].to_i
        cur_history = params[:cur_history].to_i
        max_history = params[:max_history].to_i
        memory = Filesize.new(params[:memory].to_i)
        active = !params[:active].nil?

        hash[num] = {
          :num => num,
          :width => width,
          :height => height,
          :cur_history => cur_history,
          :max_history => max_history,
          :memory => memory,
          :active => active,
        }
      end
      hash.extend FilterableHash
      hash.filter(search)
    end

    # @return [Array<Pane>] All {Pane panes}
    # @tmuxver &gt;=1.1
    attr_reader :panes
    undef_method "panes"
    def panes
      server.check_for_version!("1.1")

      panes_information.map do |num, information|
        Pane.new(self, num)
      end
    end

    # Pastes a {Buffer buffer} into the window.
    #
    # @param [Buffer] buffer The {Buffer buffer} to paste
    # @param pop (see Buffer#paste)
    # @param translate (see Buffer#paste)
    # @param separator (see Buffer#paste)
    # @return [void]
    # @tmux paste-buffer
    # @see Buffer#paste
    # @see Pane#paste
    def paste(buffer, pop = false, translate = true, separator = nil)
      buffer.paste(self, pop, translate, separator)
    end

    # Select the window.
    #
    # @return [void]
    # @tmux select-window
    def select
      server.invoke_command "select-window -t #{identifier}"
    end

    # Swap the window with another one.
    #
    # @param [Window] window The window to swap with
    # @return [void]
    # @tmux swap-window
    def swap_with(window)
      server.invoke_command "swap-window -s #{identifier} -t #{window.identifier}"
    end

    # @param [Symbol<:never, :if_same_window, :always>] return_if When
    #   to return the current pane.
    #
    #   Note: In tmux versions prior to 1.4, :always can lead to flickering
    #   Note: Since tmux version 1.4, :always is forced
    # @return [Pane, nil] The current pane
    attr_reader :current_pane
    undef_method "current_pane"
    def current_pane(return_if = :always)
      if server.version >= "1.4"
        self.panes.find(&:active?)
      else
        cur_window = self.session.any_client.current_window
        same_window = cur_window == self
        return_if_b = ((return_if == :if_same_window && same_window) || (return_if == :always))

        self.select if return_if_b && !same_window

        new_pane = nil
        if return_if_b
          num = server.invoke_command("display -p -t #{self.session.any_client.identifier} '#P'").chomp
          new_pane = Pane.new(self, num)
        end

        if return_if == :always && !same_window
          self.session.select_previous_window
        end

        return new_pane if new_pane
      end
    end

    # Reactivates a window in which the command has exited.
    #
    # @param [String, nil] command The command to use to respawn the
    #   window. If nil, the command used when the window was created is
    #   executed.
    # @param [Boolean] kill Unless `kill` is true, only inactive windows can be respawned
    # @return [void]
    # @tmux respawn-window
    # @see #remain_on_exit
    # @todo escape command
    def respawn(command = nil, kill = false)
      flags = []
      flags << "-k" if kill
      flags << "-t #{identifier}"
      flags << "\"#{command}\"" if command

      server.invoke_command "respawn-window #{flags.join(" ")}"
    end
  end
end
