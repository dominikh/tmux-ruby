module Tmux
  # A session is a single collection of pseudo terminals under the
  # management of {Tmux tmux}. Each session has one or more {Window
  # windows} linked to it. A {Window window} occupies the entire
  # screen and may be split into rectangular {Pane panes}, each of
  # which is a separate pseudo terminal (the pty(4) manual page
  # documents the technical details of pseudo terminals). Any number
  # of tmux instances may connect to the same session, and any number
  # of {Window windows} may be present in the same session. Once all
  # sessions are {Session#kill killed}, tmux exits.
  class Session
    include Comparable

    # @return [Options]
    def self.options(session)
      OptionsList.new(:session, session, true)
    end

    # Creates a new {Window window}.
    #
    # @option args [Boolean] :after_number (false) If true, the new
    #   {Window window} will be inserted at the next index up from the
    #   specified number (or the {Client#current_window current}
    #   {Window window}), moving {Window windows} up if necessary
    # @option args [Boolean] :kill_existing (false) Kill an existing
    #   {Window window} if it conflicts with a desired number
    # @option args [Boolean] :make_active (true) Switch to the newly
    #   generated {Window window}
    # @option args [String] :name Name of the new {Window window}
    #   (optional)
    # @option args [Number] :number Number of the new {Window window}
    #   (optional)
    # @option args [String] :command Command to run in the new {Window
    #   window} (optional)
    #
    # @tmux new-window
    # @return [Window] The newly created {Window window}
    def create_window(args = {})
      args = {
        :kill_existing => false,
        :make_active   => true,
        :after_number  => false,
      }.merge(args)

      flags = []
      # flags << "-d" unless args[:make_active]
      flags << "-a" if args[:after_number]
      flags << "-k" if args[:kill_existing]
      flags << "-n '#{args[:name]}'" if args[:name] # FIXME escaping
      flags << "-t #{args[:number]}" if args[:number]
      flags << args[:command] if args[:command]

      @server.invoke_command "new-window #{flags.join(" ")}"
      new_window = current_window
      unless args[:make_active]
        select_last_window
      end
      # return Window.new(self, num)
      return new_window
    end

    # @see Client#current_window
    # @return (see Client#current_window)
    attr_reader :current_window
    undef_method "current_window"
    def current_window
      any_client.current_window
    end

    # @see Client#current_pane
    # @return (see Client#current_pane)
    attr_reader :current_pane
    undef_method "current_pane"
    def current_pane
      any_client.current_pane
    end

    # Returns a {Client client} that is displaying the session.
    #
    # @return [Client, nil] A {Client client} that is displaying the session.
    def any_client
      @server.clients({:session => self}).first
    end

    # @return [Boolean]
    def ==(other)
      self.class == other.class && @server == other.server && @name == other.name
    end

    # @return [Number]
    def hash
      [@server.hash, @number].hash
    end

    # @return [Boolean]
    def eql?(other)
      self == other
    end

    def <=>(other)
      return nil unless other.is_a?(Session)
      [@server, @name] <=> [other.server, other.name]
    end

    # @overload name
    #   @return [String]
    # @overload name=(new_name)
    #   Renames the session.
    #
    #   @todo escape name
    #   @return [String]
    #   @tmux rename-session
    # @return [String]
    attr_accessor :name
    undef_method "name="
    # @return [Server]
    attr_reader :server
    # @return [OptionsList]
    attr_reader :options
    # @return [StatusBar]
    attr_reader :status_bar
    def initialize(server, name)
      @server, @name = server, name
      @status_bar = StatusBar.new(self)
      @options = OptionsList.new(:session, self, false)
    end

    def name=(new_name)
      raise ArgumentError if new_name.to_s.strip.empty?
      ret = @server.invoke_command("rename-session -t #{identifier} '#{new_name}'")

      if ret.start_with?("duplicate session:")
        raise RuntimeError, ret
      end

      @name = new_name
    end

    # @return [String]
    attr_reader :identifier
    undef_method "identifier"
    def identifier
      @name
    end

    # Locks the session.
    #
    # @tmux lock-session
    # @return [void]
    # @tmuxver &gt;=1.1
    def lock
      @server.check_for_version!("1.1")

      @server.invoke_command "lock-session -t #{identifier}"
    end

    # @return [Integer]
    attr_reader :num_windows
    undef_method "num_windows"
    def num_windows
      @server.sessions_information[@name][:num_windows]
    end

    # @return [Time]
    attr_reader :creation_time
    undef_method "creation_time"
    def creation_time
      @server.sessions_information[@name][:creation_time]
    end
    alias_method :created_at, :creation_time

    # @return [Integer]
    attr_reader :width
    undef_method "width"
    def width
      @server.sessions_information[@name][:width]
    end

    # @return [Integer]
    attr_reader :height
    undef_method "height"
    def height
      @server.sessions_information[@name][:height]
    end

    # @return [Boolean]
    attr_reader :attached
    undef_method "attached"
    def attached
      @server.sessions_information[@name][:attached]
    end
    alias_method :attached?, :attached

    # @return [Array<Client>] All {Client clients}
    attr_reader :clients
    undef_method "clients"
    def clients
      @server.clients({:session => self})
    end

    # Attach to a session. Replaces the ruby process.
    #
    # @return [void]
    # @tmux attach
    def attach
      exec "#{Tmux::BINARY} attach -t #{identifier}"
    end

    # Kills the session.
    #
    # @tmux kill-session
    # @return [void]
    def kill
      @server.invoke_command "kill-session -t #{identifier}"
    end

    # @tmux list-windows
    # @tmuxver &gt;=1.1
    # @param [Hash] search Filters the resulting hash using {FilterableHash#filter}
    # @return [Hash] A hash with information for all windows
    # @return [Hash]
    def windows_information(search = {})
      @server.check_for_version!("1.1")

      hash = {}
      output = @server.invoke_command "list-windows -t #{identifier}"
      output.each_line do |session|
        params = session.match(/^(?<num>\d+): (?<name>.+?) \[(?<width>\d+)x(?<height>\d+)\]$/)
        next if params.nil? # >=1.3 displays layout information in indented lines
        num    = params[:num].to_i
        name   = params[:name]
        width  = params[:width].to_i
        height = params[:height].to_i

        hash[num] = {:num => num, :name => name, :width => width, :height => height}
      end
      hash.extend FilterableHash
      hash.filter(search)
    end

    # @tmux list-windows
    # @return [Hash{Number => Window}] All {Window windows}
    # @tmuxver &gt;=1.1
    attr_reader :windows
    undef_method "windows"
    def windows
      hash = {}
      @server.check_for_version!("1.1")

      windows_information.each do |num, information|
        hash[num] = Window.new(self, num)
      end
      hash
    end

    # @param [Hash] search Filters the resulting hash using {FilterableHash#filter}
    # @return [Hash] A hash with information for all buffers
    # @tmux list-buffers
    def buffers_information(search = {})
      hash = {}
      buffers = @server.invoke_command "list-buffers -t #{identifier}"
      buffers.each_line do |buffer|
        num, size = buffer.match(/^(\d+): (\d+) bytes/)[1..2]
        hash[num] = {:size => size}
      end
      hash.extend FilterableHash
      hash.filter(search)
    end

    # @tmux list-buffers
    # @return [Array<Buffer>] All {Buffer buffers}
    attr_reader :buffers
    undef_method "buffers"
    def buffers
      buffers_information.map do |num, information|
        Buffer.new(num, self)
      end
    end

    # @group Selecting

    # Select the last (previously selected) window.
    #
    # @return [Window]
    def select_last_window
      @server.invoke_command "last-window -t #{identifier}"
      current_window
    end

    # Selects the next (higher index) window
    #
    # @param [Number] num How many windows to move
    # @tmuxver &gt;=1.3
    # @return [Window]
    def select_next_window(num = 1)
      @server.invoke_command "select-window -t #{identifier}:+#{num}"
      current_window
    end

    # Selects the previous (lower index) window
    #
    # @param [Number] num How many windows to move
    # @tmuxver &gt;=1.3
    # @return [Window]
    def select_previous_window(num = 1)
      @server.invoke_command "select-window -t:-#{num}"
      current_window
    end

    # @endgroup
  end
end
