require "filesize"
require "tempfile"

module Tmux
  class Buffer
    # @return [Number]
    attr_reader :number
    # @return [Session]
    attr_reader :session
    # @return [Filesize]
    def initialize(number, session)
      @number, @session, @size = number, session
      @file = Tempfile.new("buffer")
    end

    # @param [Boolean] force_reload Ignore frozen state if true
    # @return [Filesize]
    attr_reader :size
    undef_method "size"
    def size(force_reload = false)
      if @size && !force_reload
        @size
      else
        @session.buffers_information[:size]
      end
    end

    # @param [Boolean] force_reload Ignore frozen state if true
    # @return [String]
    attr_accessor :data
    undef_method "data"
    undef_method "data="
    def data(force_reload = false)
      # note: we cannot use show-buffer because that would escape tabstops
      if @data && !force_reload
        @data
      else
        server.invoke_command "save-buffer -b #@number -t #{@session.number} #{@file.path}"
        @file.read
      end
    end

    def data=(new_data)
      # FIXME maybe some more escaping?
      server.invoke_command "set-buffer -b #@number -t #{@session.number} \"#{new_data}\""
      @data = data(true) if @frozen
      @size = size(true)
    end

    # Saves the contents of a buffer.
    #
    # @param [String] file The file to write to
    # @param [Boolean] append Append to instead of overwriting the file
    # @tmux save-buffer
    # @return [void]
    def save(file, append = false)
      flag = append ? "-a" : ""
      server.invoke_command "save-buffer #{flag} -b #@number -t #{@session.number} #{file}"
    end
    alias_method :write, :save

    # By default, Buffer will not cache its data but instead query it each time.
    # By calling this method, the data will be cached and not updated anymore.
    #
    # @return [void]
    def freeze!
      @frozen = true
      @data = data
      @size = size
    end

    # @return [Server]
    attr_reader :server
    undef_method "server"
    def server
      @session.server
    end

    # Deletes a buffer.
    #
    # @tmux delete-buffer
    # @return [void]
    def delete
      freeze! # so we can still access it's old value
      server.invoke_command "delete-buffer -b #@number -t #{@session.number}"
    end

    # @return [String] The content of a buffer
    def to_s
      text
    end

    # Pastes the content of a buffer into a {Window window}.
    #
    # @param [Window] target The {Pane pane} or {Window window} to
    #   paste the buffer into. Note: {Pane Panes} as as target are only
    #   supported since tmux version 1.3.
    # @param [Boolean] pop If true, delete the buffer from the stack
    # @param [Boolean] translate If true, any linefeed (LF) characters
    #   in the paste buffer are replaced with carriage returns (CR)
    # @param [String] separator Replace any linefeed (LF) in the
    #   buffer with this separator. +translate+ must be false.
    #
    # @tmux paste-buffer
    # @tmuxver &gt;=1.3 for pasting to {Pane panes}
    # @return [void]
    # @see Window#paste
    # @see Pane#paste
    def paste(target = nil, pop = false, translate = true, separator = nil)
      if server.version < "1.3"
        if separator || target.is_a?(Pane)
          raise Exception::UnsupportedVersion, "1.3"
        end
      end

      flag_pop       = pop ? "-d" : ""
      flag_translate = translate ? "" : "-r"
      flag_separator = separator ? "" : "-s \"#{separator}\"" # FIXME escape
      window_param   = target ? "-t #{target.identifier}" : ""
      server.invoke_command "paste-buffer #{flag_pop} #{flag_translate} #{flag_separator} #{window_param}"
    end
  end
end
