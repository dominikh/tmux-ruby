module Tmux
  class Server
    # @return  [String]
    attr_reader :socket
    # @return [OptionsList]
    attr_reader :options
    # @param [String] socket A socket *name*.
    def initialize(socket = "default")
      @socket = socket
      @options = OptionsList.new(:server, self, false)
    end

    # @return [Server] Returns self. This is useful for other classes
    #   which can operate on Server, {Session}, {Window}, {Pane} and so
    #   on
    attr_reader :server
    undef_method "server"
    def server
      self
    end

    # Invokes a tmux command.
    #
    # @param [String] command The command to invoke
    # @return [void]
    def invoke_command(command)
      Tmux.invoke_command("-L #@socket #{command}")
    end

    # Kills a server and thus all {Session sessions}, {Window windows} and {Client clients}.
    #
    # @tmux kill-server
    # @return [void]
    def kill
      invoke_command "kill-server"
    end

    # Sources a file, that is load and evaluate it in tmux.
    #
    # @param [String] file Name of the file to source
    # @tmux source-file
    # @return [void]
    def source_file(file)
      invoke_command "source-file #{file}"
    end
    alias_method :load, :source_file

    # @tmux list-sessions
    # @param [Hash] search Filters the resulting hash using {FilterableHash#filter}
    # @return [Hash] A hash with information for all sessions
    def sessions_information(search = {})
      hash = {}
      output = invoke_command "list-sessions"
      output.each_line do |session|
        params = session.match(/^(?<name>\w+?): (?<num_windows>\d+) windows \(created (?<creation_time>.+?)\) \[(?<width>\d+)x(?<height>\d+)\](?: \((?<attached>attached)\))?$/)

        name          = params[:name]
        num_windows   = params[:num_windows].to_i
        creation_time = Date.parse(params[:creation_time])
        width         = params[:width].to_i
        height        = params[:height].to_i
        attached      = !!params[:attached]

        hash[name] = {
          :name          => name,
          :num_windows   => num_windows,
          :creation_time => creation_time,
          :width         => width,
          :height        => height,
          :attached      => attached,
        }
      end
      hash.extend FilterableHash
      hash.filter(search)
    end

    # @tmux list-sessions
    # @return [Array<Session>] All {Session sessions}
    attr_reader :sessions
    undef_method "sessions"
    def sessions(search = {})
      sessions_information(search).map do |name, information|
        Session.new(self, name)
      end
    end

    # @return [Session] The first {Session session}. This is
    #   especially useful if working with a server that only has one
    #   {Session session}.
    attr_reader :session
    undef_method "session"
    def session
      sessions.first
    end

    # @tmux list-clients
    # @param [Hash] search Filters the resulting hash using {FilterableHash#filter}
    # @return [Hash] A hash with information for all clients
    # @return [Hash]
    def clients_information(search = {})
      clients = invoke_command "list-clients"
      hash = {}
      clients.each_line do |client|
        params  = client.match(/^(?<device>.+?): (?<session>\d+) \[(?<width>\d+)x(?<height>\d+) (?<term>.+?)\](?: \((?<utf8>utf8)\))?$/)
        device  = params[:device]
        session = sessions[params[:session].to_i]
        width   = params[:width].to_i
        height  = params[:height].to_i
        term    = params[:term]
        utf8    = !!params[:utf8]

        hash[device] = {
          :device => device,
          :session => session,
          :width => width,
          :height => height,
          :term => term,
          :utf8 => utf8,
        }
      end
      hash.extend FilterableHash
      hash.filter(search)
      # hash.select { |device, client|
      #   client.all? { |key, value|
      #     !search.has_key?(key) || value == search[key]
      #   }
      # }
    end

    # @tmux list-clients
    # @return [Array<Client>]
    attr_reader :clients
    undef_method "clients"
    def clients(search = {})
      clients_information(search).map { |device, information|
        Client.new(self, device)
      }
    end

    # @tmux server-info
    # @return [String] Information about the server
    attr_reader :info
    undef_method "info"
    def info
      invoke_command "server-info"
    end

    # @return [String] Version of the tmux server
    attr_reader :version
    undef_method "version"
    def version
      @version ||= info.lines.first.split(",").first[/([.\d]+)/]
    end

    # Checks if a version requirement is being met
    #
    # @param [String] required The version at least required
    # @raise [Exception::UnsupportedVersion] Raised if a version requirement isn't met
    # @return [void]
    def check_for_version!(required)
      if required > version
        raise Exception::UnsupportedVersion, required
      end
    end
  end
end
