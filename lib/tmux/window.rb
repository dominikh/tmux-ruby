require "tmux/window/status"

module Tmux
  # A {Window window} occupies the entire
  # screen and may be split into rectangular {Pane panes}, each of
  # which is a separate pseudo terminal (the pty(4) manual page
  # documents the technical details of pseudo terminals).
  class Window
    include Comparable

    # @return [OptionsList]
    def self.options(server)
      OptionsList.new(:window, server, true)
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
        # 2: [44x11] [history 48/2000, 3945 bytes]
        params = pane.match(/^(?<num>\d+): \[(?<width>\d+)x(?<height>\d+)\] \[history (?<cur_history>\d+)\/(?<max_history>\d+), (?<memory>\d+) bytes\]$/)
        num = params[:num].to_i
        width = params[:width].to_i
        height = params[:height].to_i
        cur_history = params[:cur_history].to_i
        max_history = params[:max_history].to_i
        memory = Filesize.new(params[:memory].to_i)

        hash[num] = {
          :num => num,
          :width => width,
          :height => height,
          :cur_history => cur_history,
          :max_history => max_history,
          :memory => memory,
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

    # @param [Symbol<:never, :if_same_window, :always>] return_new whether to return the pane we moved
    #   to. Note: this might produce a short flickering if we have
    #   to move to the appropriate window and back.
    # @return [Pane, nil]
    attr_reader :current_pane
    undef_method "current_pane"
    def current_pane(return_if = :always)
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
end
