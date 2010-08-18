module Tmux
  # A {Window window} occupies the entire
  # screen and may be split into rectangular {Pane panes}, each of
  # which is a separate pseudo terminal (the pty(4) manual page
  # documents the technical details of pseudo terminals).
  class Pane
    include Comparable

    # @return [Window]
    attr_reader :window
    # @return [Number]
    attr_reader :number
    def initialize(window, number)
      @window, @number = window, number
    end

    # @return [Boolean]
    def ==(other)
      self.class == other.class && @window == other.window && @number = other.number
    end

    # @return [Number]
    def hash
      [@window.hash, @number].hash
    end

    # @return [Boolean]
    def eql?(other)
      self == other
    end

    def <=>(other)
      return nil unless other.is_a?(Pane)
      [@window, @number] <=> [other.window, other.number]
    end

    # @return [Server]
    attr_reader :server
    undef_method "server"
    def server
      @window.server
    end

    # @return [String]
    attr_reader :identifier
    undef_method "identifier"
    def identifier
      @window.identifier + "." + @number.to_s
    end

    # @return [Integer]
    # @tmuxver &gt;=1.1
    attr_reader :width
    undef_method "width"
    def width
      server.check_for_version!("1.1")

      @window.panes_information[@number][:width]
    end

    # @return [Integer]
    # @tmuxver &gt;=1.1
    attr_reader :height
    undef_method "height"
    def height
      server.check_for_version!("1.1")

      @window.panes_information[@number][:height]
    end

    # @return [Integer]
    # @tmuxver &gt;=1.1
    attr_reader :max_history_size
    undef_method "max_history_size"
    def max_history_size
      server.check_for_version!("1.1")

      @window.panes_information[@number][:max_history]
    end

    # @return [Integer]
    # @tmuxver &gt;=1.1
    attr_reader :current_history_size
    undef_method "current_history_size"
    def current_history_size
      server.check_for_version!("1.1")

      @window.panes_information[@number][:cur_history]
    end

    # @return [Filesize]
    # @tmuxver &gt;=1.1
    attr_reader :memory_usage
    undef_method "memory_usage"
    def memory_usage
      server.check_for_version!("1.1")

      @window.panes_information[@number][:memory]
    end

    # @return [Boolean] True if the pane is the currently selected one
    #   in its window.
    # @tmuxver &gt;=1.4
    attr_reader :active
    undef_method "active"
    def active
      server.check_for_version!("1.4")

      @window.panes_information[@number][:active]
    end
    alias_method :active?, :active

    # @group Modes

    # Enter copy mode.
    #
    # @return [void]
    # @tmuxver &gt;=1.0
    # @tmux copy-mode
    def copy_mode
      server.check_for_version!("1.0")

      server.invoke_command "copy-mode -t #{identifier}"
    end

    # Displays a clock in the pane.
    #
    # @return [void]
    # @tmuxver &gt;=1.0
    # @tmux clock-mode
    def clock_mode
      server.check_for_version!("1.0")

      server.invoke_command "clock-mode -t #{identifier}"
    end
    alias_method :show_clock, :clock_mode

    # @endgroup

    # Breaks the pane off from its containing {Window window} to make
    # it the only pane in a new {Window window}.
    #
    # @param [Boolean] select If true, the new {Window window} will be
    #   selected automatically
    # @return [Pane]
    # @tmuxver &gt;=1.0
    # @tmux break-pane
    def break(select = true)
      server.check_for_version!("1.0")

      server.invoke_command "break-pane -t #{identifier}"
      num_window, num_pane = server.invoke_command("display -p -t #{@window.session.any_client.identifier} '#I:#P'").chomp.split(":")
      session = @window.session
      window  = Window.new(session, num_window)
      pane    = Pane.new(window, num_pane)
      unless select
        session.select_last_window
      end
      return pane
    end

    # @group Killing

    # Kills the pane.
    #
    # @tmux kill-pane
    # @return [void]
    # @tmuxver &gt;=1.0
    def kill
      server.check_for_version!("1.0")

      server.invoke_command "kill-pane -t #{identifier}"
    end

    # Kills all other panes.
    #
    # @tmux kill-pane -a
    # @return [void]
    # @tmuxver &gt;=1.1
    def kill_others
      server.check_for_version!("1.1")

      server.invoke_command "kill-pane -a -t #{identifier}"
    end

    # @endgroup

    # Removes and frees the history of the pane.
    #
    # @tmux clear-history
    # @return [void]
    # @tmuxver &gt;=1.0
    def clear_history
      server.check_for_version!("1.0")

      server.invoke_command "clear-history -t #{identifier}"
    end

    # Swaps the pane with another one.
    #
    # @param [Pane] pane The pane to swap with.
    # @return [void]
    # @tmuxver &gt;=1.0
    def swap_with(pane)
      server.check_for_version!("1.0")

      server.invoke_command "swap-pane -s #{identifier} -t #{pane.identifier}"
    end

    # @group Input

    # Sends a key to the pane.
    #
    # @param [String] key
    # @see #send_keys
    # @return [void]
    # @tmuxver &gt;=1.0
    def send_key(key)
      server.check_for_version!("1.0")

      send_keys([key])
    end

    # Sends keys to the pane.
    #
    # @param [Array<String>] keys
    # @return [void]
    # @tmuxver &gt;=1.0
    def send_keys(keys)
      server.check_for_version!("1.0")

      keychain = []
      keys.each do |key|
        case key
        when '"'
          keychain << '"\\' + key + '"'
        else
          keychain << '"' + key + '"'
        end
      end
      server.invoke_command "send-keys -t #{identifier} #{keychain.join(" ")}"
    end

    # Runs a command in the pane. Note: this is experimental, hacky
    # and might and will break.
    #
    # @param [String] command
    # @return [void]
    # @tmuxver &gt;=1.0
    def run(command)
      server.check_for_version!("1.0")

      write(command)
      send_key "Enter"
    end

    # Writes text to the pane. This is basically the same as {Pane#run},
    # but without sending a final Return.
    #
    # @param [String] text
    # @tmuxver &gt;=1.0
    # @return [void]
    # @see Pane#run
    def write(text)
      server.check_for_version!("1.0")

      send_keys(text.split(""))
    end

    # Pastes a {Buffer buffer} into the pane.
    #
    # @param [Buffer] buffer The {Buffer buffer} to paste
    # @param pop (see Buffer#paste)
    # @param translate (see Buffer#paste)
    # @param separator (see Buffer#paste)
    # @return [void]
    # @tmux paste-buffer
    # @see Buffer#paste
    # @see Window#paste
    # @tmuxver &gt;=1.3
    def paste(buffer, pop = false, translate = true, separator = nil)
      server.check_for_version!("1.3")

      buffer.paste(self, pop, translate, separator)
    end

    # @endgroup

    # Split the pane and move an existing pane into the new area.
    #
    # @param [Pane] pane The {Pane pane} to join
    #
    # @option args [Boolean] :make_active (true) Switch to the newly generated pane
    # @option args [Symbol<:vertical, :horizontal>] :direction (:vertical) The direction to split in
    # @option args [Number] :size Size of the new pane in lines (for vertical split) or in cells (for horizontal split)
    # @option args [Number] :percentage Size of the new pane in percent.
    def join(pane, args = {})
      server.check_for_version!("1.2")
      args = {
        :make_active => true,
        :direction   => :vertical,
      }.merge(args)
      flags = split_or_join_flags(args)
      flags << "-s #{pane.identifier}"
      flags << "-t #{identifier}"

      server.invoke_command "join-pane #{flags.join(" ")} "
      if args[:make_active]
        num = server.invoke_command("display -p -t #{@window.session.any_client.identifier} '#P'").chomp
        return Pane.new(@window, num)
      else
        return nil
      end
    end

    # join-pane    [-dhv] [-l size | -p percentage] [-s src-pane] [-t dst-pane]
    # split-window [-dhv] [-l size | -p percentage] [-t target-pane] [shell-command]

    def split_or_join_flags(args)
      flags = []
      flags << "-d" unless args[:make_active]
      flags << case args[:direction]
               when :vertical
                 "-v"
               when :horizontal
                 "-h"
               else
                 raise ArgumentError
               end

      raise ArgumentError if args[:size] && args[:percentage]
      if args[:size]
        flags << "-l #{args[:size]}"
      elsif args[:percentage]
        flags << "-p #{args[:percentage]}"
      end

      return flags
    end
    private :split_or_join_flags

    # Splits the pane.
    #
    # @return [Pane, nil] Returns the newly created pane, but only if
    #   :make_active is true. See
    #   http://sourceforge.net/tracker/?func=detail&aid=3030471&group_id=200378&atid=973265
    #   for more information.
    #
    # @option args [Boolean] :make_active (true) Switch to the newly generated pane
    # @option args [Symbol<:vertical, :horizontal>] :direction (:vertical) The direction to split in
    # @option args [Number] :size Size of the new pane in lines (for vertical split) or in cells (for horizontal split)
    # @option args [Number] :percentage Size of the new pane in percent.
    # @option args [String] :command Command to run in the new pane (optional)
    #
    # @tmux split-window
    # @tmuxver &gt;=1.2
    def split(args = {})
      server.check_for_version!("1.2")
      args = {
        :make_active => true,
        :direction   => :vertical,
      }.merge(args)
      flags = split_or_join_flags(args)

      flags << "-t #{identifier}"
      flags << '"' + args[:command] + '"' if args[:command] # TODO escape

      server.invoke_command "split-window #{flags.join(" ")} "
      if args[:make_active]
        num = server.invoke_command("display -p -t #{@window.session.any_client.identifier} '#P'").chomp
        return Pane.new(@window, num)
      else
        return nil
      end
    end

    # Resizes the pane.
    #
    # @param [Symbol<:up, :down, :left, :right>] direction Direction
    #   in which to resize
    # @param [Number] adjustment How many lines or cells to resize.
    # @return [void]
    def resize(direction, adjustment = 1)
      raise ArgumentError unless [:up, :down, :left, :right].include?(direction)
      direction = direction.to_s.upcase[0..0]
      server.invoke_command "resize-pane -#{direction} -t #{identifier} #{adjustment}"
    end

    # @group Selecting

    # @param [Symbol<:up, :down, :left, :right>] direction direction to move to
    # @param [Symbol<:never, :if_same_window, :always>] return_new whether to return the pane we moved
    #   to.
    #
    #   Note: In tmux versions prior to 1.4, :always can lead to flickering
    #   Note: Since tmux version 1.4, :always is forced
    # @tmuxver &gt;=1.3
    # @return [Pane, nil]
    def select_direction(direction, return_new = :if_same_window)
      raise ArgumentError unless [:up, :down, :left, :right].include?(direction)
      direction = direction.to_s.upcase[0..0]
      server.invoke_command "select-pane -#{direction} -t #{identifier}"

      return @window.current_pane(return_new)
    end

    # @tmuxver (see Tmux::Pane#select_direction)
    # @param return_new (see Tmux::Pane#select_direction)
    # @return (see Tmux::Pane#select_direction)
    # @see Pane#select_direction
    def select_up(return_new = :if_same_window)
      select_direction(:up, return_new)
    end

    # @tmuxver (see Tmux::Pane#select_direction)
    # @param return_new (see Tmux::Pane#select_direction)
    # @return (see Tmux::Pane#select_direction)
    # @see Pane#select_direction
    def select_down(return_new = :if_same_window)
      select_direction(:down, return_new)
    end

    # @tmuxver (see Tmux::Pane#select_direction)
    # @param return_new (see Tmux::Pane#select_direction)
    # @return (see Tmux::Pane#select_direction)
    # @see Pane#select_direction
    def select_left(return_new = :if_same_window)
      select_direction(:left, return_new)
    end

    # @tmuxver (see Tmux::Pane#select_direction)
    # @param return_new (see Tmux::Pane#select_direction)
    # @return (see Tmux::Pane#select_direction)
    # @see Pane#select_direction
    def select_right(return_new = :if_same_window)
      select_direction(:right, return_new)
    end

    # @return [Pane, nil]
    # @param [Number] num how many panes to move down. Note: will be ignored on tmux versions <1.3
    # @param return_new (see Tmux::Pane#select_direction)
    # @tmuxver &gt;=1.3 for `num` parameter
    # @tmux down-pane or select-pane -t:+
    def select_next(num = 1, return_new = :if_same_window)
      if server.version > "1.2"
        server.invoke_command "select-pane -t #{@window.identifier}.+#{num}"
      else
        server.invoke_command "down-pane -t #{identifier}"
      end

      return @window.current_pane(return_new)
    end

    # @return [Pane, nil]
    # @param [Number] num how many panes to move up. Note: will be ignored on tmux versions <1.3
    # @param return_new (see Tmux::Pane#select_direction)
    # @tmuxver &gt;=1.3 for `num` parameter
    # @tmux up-pane or select-pane -t:-
    def select_previous(num = 1, return_new = :if_same_window)
      if server.version > "1.2"
        server.invoke_command "select-pane -t #{@window.identifier}.-#{num}"
      else
        server.invoke_command "up-pane -t #{identifier}"
      end

      return @window.current_pane(return_new)
    end

    # Selects the pane.
    #
    # @return [void]
    # @tmuxver &gt;=1.0
    def select
      server.check_for_version!("1.0")

      server.invoke_command "select-pane -t #{identifier}"
    end

    # @endgroup
  end
end
