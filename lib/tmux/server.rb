# -*- coding: utf-8 -*-
module Tmux
  class Server
    include Comparable

    # Creates a new session
    #
    # @option args [Boolean] :attach (false) Attach to the new session?
    # @option args [String] :name (nil) Name of the new session. Will
    #   be automatically generated of nil.
    # @option args [String] :window_name (nil) Name of the initial
    #   window. Cannot be used when grouping sessions.
    # @option args [Session] :group_with (nil) Group with this
    #   session, sharing all windows.
    # @option args [String] :command (nil) Execute this command in the
    #   initial window. Cannot be used when grouping sessions.
    #
    # @return [Session, nil] Returns the new {Session session} if a
    #   `:name` has been given and if `:attach` is false
    #
    # @raise [ArgumentError] if combining `:group_with` and `:window_name`
    #   or :command
    #
    # @tmuxver &gt;=1.4
    def create_session(args = {})
      check_for_version!("1.4")

      if args[:group_with] && (args[:window_name] || args[:command])
        raise ArgumentError, "Cannot combine :group_with and :window_name or :command"
      end

      # FIXME shell escape names
      flags = []
      flags << "-d" unless args[:attach]
      flags << "-n '#{args[:window_name]}'"     if args[:window_name]
      flags << "-s '#{args[:name]}'"            if args[:name]
      flags << "-t '#{args[:group_with].name}'" if args[:group_with]
      flags << args[:command]                   if args[:command]

      command = "new-session #{flags.join(" ")}"

      ret = invoke_command(command, true)
      if ret.start_with?("duplicate session:")
        raise RuntimeError, ret
      elsif ret.start_with?("sessions should be nested with care.")
        raise Exception::InTmux("new-session")
      else
        if args[:name] and !args[:attach]
          return Session.new(self, args[:name])
        end
      end
    end

    # @return  [String]
    attr_reader :socket
    # @return [OptionsList]
    attr_reader :options
    # @param [String] socket A socket *name*.
    def initialize(socket = "default")
      @socket = socket
      @options = OptionsList.new(:server, self, false)
    end

    def <=>(other)
      return nil unless other.is_a?(Server)
      @socket <=> other.socket
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
    def invoke_command(command, unset_tmux = false)
      Tmux.invoke_command("-L #@socket #{command}", unset_tmux)
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
        params = session.match(/^(?<name>\w+?): (?<num_windows>\d+) windows \(created (?<creation_time>.+?)\) \[(?<width>\d+)x(?<height>\d+)\](?: \(group (?<group>\d+)\))?(?: \((?<attached>attached)\))?$/)

        name          = params[:name]
        num_windows   = params[:num_windows].to_i
        creation_time = Date.parse(params[:creation_time])
        width         = params[:width].to_i
        height        = params[:height].to_i
        group         = params[:group].to_i if params[:group]
        attached      = !!params[:attached]

        hash[name] = {
          :name          => name,
          :num_windows   => num_windows,
          :creation_time => creation_time,
          :width         => width,
          :height        => height,
          :group         => group,
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
