module Tmux
  class Client
    # @return [Server]
    attr_reader :server

    # @return [String]
    attr_reader :device

    def initialize(server, device)
      @server, @device = server, device
    end

    # @!attribute [r] identifier
    # @return [String]
    def identifier
      @device
    end

    # @!attribute session
    #
    # Setting this will make a client switch to another {Session session}.
    #
    # @tmux switch-client
    # @return [Session]
    def session
      @server.clients_information[@device][:session]
    end

    def session=(new_session)
      @server.invoke_command "switch-client -c #@device -t #{new_session.number}"
    end

    # @!attribute [r] width
    #
    # @return [Integer]
    def width
      @server.clients_information[@device][:width]
    end

    # @!attribute [r] height
    # @return [Integer]
    def height
      @server.clients_information[@device][:height]
    end

    # @!attribute [r] term
    #
    # $TERM of a client.
    #
    # @return [String]
    def term
      @server.clients_information[@device][:term]
    end

    # @!attribute [r] utf8
    # True if the terminal is using UTF-8.
    #
    # @return [Boolean]
    def utf8
      @server.clients_information[@device][:utf8]
    end
    alias_method :utf8?, :utf8

    # Detaches a client from tmux.
    #
    # @tmux detach-client
    # @return [void]
    def detach
      @server.invoke_command "detach-client -t #@device"
    end

    # Locks a client.
    #
    # @tmux lock-client
    # @return [void]
    # @tmuxver &gt;=1.1
    def lock
      @server.check_for_version!("1.1")

      @server.invoke_command "lock-client -t #@device"
    end

    # Suspends a client.
    #
    # @tmux suspend-client
    # @return [void]
    def suspend
      @server.invoke_command "suspend-client -c #@device"
    end

    # Refreshs a client.
    #
    # @tmux refresh-client
    # @return [void]
    def refresh
      @server.invoke_command "refresh-client -t #@device"
    end

    # @!attribute [r] messages
    #
    # @tmux show-messages
    # @return [Array<String>] A log of messages
    # @tmuxver &gt;=1.2
    def messages
      @server.check_for_version!("1.2")

      @server.invoke_command("show-messages -t #@device").split("\n")
    end

    # Displays a visible indicator of each {Pane pane} shown by a client.
    #
    # @tmux display-panes
    # @return [void]
    # @tmuxver &gt;=1.0
    def display_panes
      @server.check_for_version!("1.0")

      @server.invoke_command("display-panes -t #@device")
    end

    # @!attribute [r] current_window
    #
    # @return [Window] The currently displayed {Window window}.
    # @tmuxver &gt;=1.2
    def current_window
      @server.check_for_version!("1.2")

      client_switch = @server.version < "1.5" ? "-t" : "-c"
      num = @server.invoke_command("display -p #{client_switch} #@device '#I'").chomp
      session.windows[num.to_i]
    end

    # @!attribute [r] current_pane
    #
    # @return [Pane] The currently displayed {Pane pane}.
    # @tmuxver &gt;=1.2
    def current_pane
      @server.check_for_version!("1.2")

      output = @server.invoke_command "display-message -p -t #@device"
      current_pane = output.match(/^.+?, current pane (\d+) . .+$/)[1]
      current_window.panes[current_pane.to_i]
    end

    # Displays a message.
    #
    # @param [String] text The message to display
    # @tmux display-message
    # @return [void]
    # @tmuxver &gt;=1.0
    def message(text)
      @server.check_for_version!("1.0")

      @server.invoke_command "display-message -t #@device \"#{text}\""
    end

    # Opens a prompt inside a client allowing a {Window window} index to be entered interactively.
    #
    # @tmux command-prompt + select-window
    # @return [void]
    def select_interactively
      command_prompt "select-window -t:%%", ["index"]
    end

    # Opens a command prompt in the client. This may be used to
    # execute commands interactively.
    #
    # @param [String] template The template is used as the command to
    #   execute. Before the command is executed, the first occurrence
    #   of the string '%%' and all occurrences of '%1' are replaced by
    #   the response to the first prompt, the second '%%' and all '%2'
    #   are replaced with the response to the second prompt, and so on
    #   for further prompts. Up to nine prompt responses may be
    #   replaced ('%1' to '%9')
    #
    # @param [Array<String>] prompts prompts is a list
    #   of prompts which are displayed in order; otherwise a single
    #   prompt is displayed, constructed from template
    #
    # @return [void]
    # @tmux command-prompt
    # @todo escape prompts and template
    def command_prompt(template, prompts = [])
      prompts = prompts.join(",")
      flags = []
      flags << "-p #{prompts}" unless prompts.empty?
      flags << "-t #{identifier}"
      flags << "\"#{template}\""
      @server.invoke_command "command-prompt #{flags.join(" ")}"
    end
  end
end
