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
      def options(server)
        OptionsList.new(:window, server, true)
      end
    end

    # @return [Number]
    attr_reader :number

    # @return [Session]
    attr_reader :session

    # @return [OptionsList]
    attr_reader :options

    # @return [Status]
    attr_reader :status
    def initialize(session, number)
      @session, @number = session, number
      @options = OptionsList.new(:window, self, false)
      @status = Status.new(self)
    end

    # @!attribute session
    #
    # Moves the window to another {Session session}. First it tries
    # to reuse the current number of the window. If that number is
    # already used in the new {Session session}, the first free
    # number will be used instead.
    #
    # @return [Session]
    # @raise [Exception::IndexInUse]
    # @see #move
    # @todo use base-index
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

    # @!attribute number
    # @return [Number]
    # @raise [Exception::IndexInUse]
    # @see #move
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

    # @!attribute [r] server
    #
    # @return [Server]
    def server
      @session.server
    end

    # @!attribute name
    # @return [String]
    # @tmuxver &gt;=1.1
    # @tmux rename-window
    def name
      server.check_for_version!("1.1")

      @session.windows_information[@number][:name]
    end

    # @return [String]
    def name=(value)
      # TODO escape name?
      server.invoke_command "rename-window -t #{identifier} '#{value}'"
    end

    # @!attribute [r] width
    #
    # @return [Integer]
    # @tmuxver &gt;=1.1
    def width
      server.check_for_version!("1.1")

      @session.windows_information[@number][:width]
    end

    # @!attribute [r] height
    #
    # @return [Integer]
    # @tmuxver &gt;=1.1
    def height
      server.check_for_version!("1.1")

      @session.windows_information[@number][:height]
    end

    # @!attribute [r] identifier
    #
    # @return [String]
    def identifier
      "%s:%s" % [@session.identifier, @number]
    end

    # @!attribute aggressive_resize
    #
    # Aggressively resize the window. This means that tmux will resize
    # the window to the size of the smallest {Session session} for
    # which it is the current window, rather than the smallest
    # {Session session} to which it is attached. The window may resize
    # when the current window is changed on another {Session session};
    # this option is good for full-screen programs which support
    # SIGWINCH and poor for interactive programs such as shells.
    #
    # @return [Boolean]
    def aggressive_resize
      @options.aggressive_resize
    end
    alias_method :aggressive_resize?, :aggressive_resize

    # @param [Boolean] bool
    # @return [Boolean]
    def aggressive_resize=(bool)
      @options.aggressive_resize = bool
    end

    # @!attribute automatic_rename
    #
    # Control automatic window renaming. When this setting is enabled,
    # tmux will attempt – on supported platforms – to rename the
    # window to reflect the command currently running in it. This flag
    # is automatically disabled for an individual window when a name
    # is specified at creation with {Session#create_window} or
    # {Server#create_session}, or later with {#name=}.
    #
    # @return [Boolean]
    def automatic_rename
      @options.automatic_rename
    end
    alias_method :automatic_rename?, :automatic_rename

    # @param [Boolean] bool
    # @return [Boolean]
    def automatic_rename=(bool)
      @options.automatic_rename = bool
    end

    # @!attribute synchronize_panes
    #
    # Duplicate input to any {Pane pane} to all other {Pane panes} in
    # the same window (only for {Pane panes} that are not in any
    # special mode)
    #
    # @return [Boolean]
    def synchronize_panes
      @options.synchronize_panes
    end
    alias_method :synchronize_panes?, :synchronize_panes

    # @param [Boolean] bool
    # @return [Boolean]
    def synchronize_panes=(bool)
      @options.synchronize_panes = bool
    end

    # @!attribute remain_on_exit
    # A window with this flag set is not destroyed when the program
    # running in it exits. The window may be reactivated with
    # {#respawn}.
    #
    # @return [Boolean]
    def remain_on_exit
      @options.remain_on_exit
    end
    alias_method :remain_on_exit?, :remain_on_exit

    # @param [Boolean] bool
    # @return [Boolean]
    def remain_on_exit=(bool)
      @options.remain_on_exit = bool
    end

    # @!attribute utf8
    #
    # Instructs tmux to expect UTF-8 sequences to appear in this
    # window.
    #
    # @return [Boolean]
    def utf8
      @options.utf8
    end
    alias_method :utf8?, :utf8

    # @param [Boolean] bool
    # @return [Boolean]
    def utf8=(bool)
      @options.utf8 = bool
    end

    # @!attribute monitor_activity
    #
    # Monitor for activity in the window. Windows with activity are
    # highlighted in the {StatusBar status line}.
    #
    # @return [Boolean]
    def monitor_activity
      @options.monitor_activity
    end
    alias_method :monitor_activity?, :monitor_activity

    # @param [Boolean] bool
    # @return [Boolean]
    def monitor_activity=(bool)
      @options.monitor_activity = bool
    end

    # @!attribute monitor_content
    #
    # Monitor content in the window. When the
    # {http://linux.die.net/man/3/fnmatch fnmatch(3)} pattern appears
    # in the window, it is highlighted in the {StatusBar status line}.
    #
    # @return [String]
    def monitor_content
      @options.monitor_content
    end

    # @param [String] pattern
    # @return [String]
    def monitor_content=(pattern)
      @options.monitor_content = pattern
    end

    # @!attribute max_width
    #
    # Prevent tmux from resizing the window to greater than
    # `max_width`. A value of zero restores the default unlimited
    # setting.
    #
    # @return [Number]
    def max_width
      @options.force_width
    end

    # @param [Number] value
    # @return [Number]
    def max_width=(value)
      @options.force_width = value
    end
    alias_method :force_width, :max_width
    alias_method :force_width=, "max_width="

    # @!attribute max_height
    #
    # Prevent tmux from resizing the window to greater than
    # `max_height`. A value of zero restores the default unlimited
    # setting.
    #
    # @return [Number]
    def max_height
      @options.force_height
    end

    # @param [Number] value
    # @return [Number]
    def max_height=(value)
      @options.force_height = value
    end
    alias_method :force_height, :max_height
    alias_method :force_height=, "max_height="

    # @!attribute xterm_keys
    #
    # If this option is set to true, tmux will generate
    # {http://linux.die.net/man/1/xterm xterm(1)}-style function key
    # sequences. These have a number included to indicate modifiers
    # such as Shift, Alt or Ctrl. The default is false.
    #
    # @return [Boolean]
    def xterm_keys
      @options.xterm_keys
    end
    alias_method :xterm_keys?, :xterm_keys

    # @param [Boolean] bool
    # @return [Boolean]
    def xterm_keys=(bool)
      @options.xterm_keys = bool
    end

    # @!attribute word_separators
    #
    # Sets the window's conception of what characters are considered
    # word separators, for the purposes of the next and previous word
    # commands in {Pane#copy_mode copy mode}. The default is `[" ",
    # "-", "_", "@"]`.
    #
    # @return [Array<String>]
    def word_separators
      @options.word_separators
    end

    # @param [Array<String>] value
    # @return [Array<String>]
    def word_separators=(value)
      @options.word_separators = value
    end

    # @!attribute alternate_screen
    # This option configures whether programs running inside tmux may
    # use the terminal alternate screen feature, which allows the
    # smcup and rmcup {http://linux.die.net/man/5/terminfo
    # terminfo(5)} capabilities to be issued to preserve the existing
    # window content on start and restore it on exit.
    #
    # @return [Boolean]
    def alternate_screen
      @options.alternate_screen
    end
    alias_method :alternate_screen?, :alternate_screen

    # @param [Boolean] bool
    # @return [Boolean]
    def alternate_screen=(bool)
      @options.alternate_screen = bool
    end

    # @!attribute mode_mouse
    #
    # Mouse state in modes. If true, the mouse may be used to copy a
    # selection by dragging in {Pane#copy_mode copy mode}, or to
    # select an option in choice mode.
    #
    # @return [Boolean]
    def mode_mouse
      @options.mode_mouse
    end
    alias_method :mode_mouse?, :mode_mouse

    # @param [Boolean] bool
    # @return [Boolean]
    def mode_mouse=(bool)
      @options.mode_mouse = bool
    end

    # @!attribute clock_mode_colour
    #
    # Clock color.
    #
    # @return [Symbol]
    def clock_mode_color
      @options.clock_mode_colour
    end
    alias_method :clock_mode_colour, :clock_mode_color

    # @param [Symbol] color
    # @return [Symbol]
    def clock_mode_color=(color)
      @options.clock_mode_colour = color
    end
    alias_method :clock_mode_colour=, "clock_mode_color="

    # @!attribute clock_mode_style
    #
    # Clock hour format.
    #
    # @return [Symbol<:twelve, :twenty_four>]
    def clock_mode_style
      @options.clock_mode_style
    end

    # @param [Symbol<:twelve, :twenty_four>] style
    # @return [Symbol]
    def clock_mode_style=(style)
      @options.clock_mode_style = style
    end

    # @!attribute main_pane_height
    #
    # The height of the main (left or top) pane in the
    # main-horizontal or main-vertical {#layout= layouts}.
    #
    # @return [Number]
    # @see #layout=
    def main_pane_height
      @options.main_pane_height
    end

    # @param [Number] height
    # @return [Number]
    def main_pane_height=(height)
      @options.main_pane_height = height
    end

    # @!attribute main_pane_width
    #
    # The width of the main (left or top) pane in the
    # main-horizontal or main-vertical {#layout= layouts}.
    #
    # @return [Number]
    # @see #layout=
    def main_pane_width
      @options.main_pane_width
    end

    # @param [Number] width
    # @return [Number]
    def main_pane_width=(width)
      @options.main_pane_width = width
    end

    # @!attribute mode_attr
    #
    # @return [Symbol]
    def mode_attr
      @options.mode_attr
    end

    # @param [Symbol] attr
    # @return [Symbol]
    def mode_attr=(attr)
      @options.mode_attr = attr
    end

    # @!attribute mode_bg
    # @return [Symbol]
    def mode_bg
      @options.mode_bg
    end

    # @param [Symbol] bg
    # @return [Symbol]
    def mode_bg=(bg)
      @options.mode_bg = bg
    end

    # @!attribute mode_fg
    # @return [Symbol]
    def mode_fg
      @options.mode_fg
    end

    # @param [Symbol] fg
    # @return [Symbol]
    def mode_fg=(fg)
      @options.mode_fg = fg
    end

    # @!attribute mode_keys
    #
    # @return [Symbol]
    def mode_keys
      @options.mode_keys
    end

    # @param [Symbol] keymap
    # @return [Symbol]
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

    # @!attribute [w] layout
    #
    # @todo attr_reader
    # @return [Symbol<:even_horizontal, :even_vertical, :main_horizontal, :main_vertical>]
    # @tmux select-layout
    # @tmuxver &gt;=1.3 for :tiled layout
    # @tmuxver &gt;=1.0 for all other layouts
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
        params = pane.match(/^(?<num>\d+): \[(?<width>\d+)x(?<height>\d+)\] \[history (?<cur_history>\d+)\/(?<max_history>\d+), (?<memory>\d+) bytes\]( %\d+)?(?<active> \(active\))?$/)
        num = params[:num].to_i
        width = params[:width].to_i
        height = params[:height].to_i
        cur_history = params[:cur_history].to_i
        max_history = params[:max_history].to_i
        memory = Filesize.new(params[:memory].to_i)

        # this flag requires tmux >=1.4
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

    # @!attribute [r] panes
    #
    # @return [Array<Pane>] All {Pane panes}
    # @tmuxver &gt;=1.1
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
    def current_pane(return_if = :always)
      if server.version >= "1.4"
        self.panes.find(&:active?)
      else
        # In tmux <1.4, we can only determine the selected pane of the
        # current window.
        #
        # If the user specified return_if = :always, we select this
        # window (if it is not already selected), determine the
        # current pane and select the lastly selected window again.
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

    # Select the previously selected pane.
    #
    # @param return_if (see Window#current_pane)
    # @return (see Window#current_pane)
    # @tmux last-pane
    # @tmuxver &gt;=1.4
    def select_last_pane(return_if = :always)
      server.invoke_command("last-pane -t #{identifier}")
      current_pane(return_if)
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
