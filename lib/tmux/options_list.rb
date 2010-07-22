module Tmux
  # OptionsList offers an easy way of querying and setting tmux
  # options, taking care of typecasting. Note: You should not have to
  # instantiate this class but use the respective `::options` and
  # `#options` methods instead.
  #
  # @see Server#options
  # @see Session.options
  # @see Session#options
  # @see Window.options
  # @see Window#options
  class OptionsList
    include Enumerable
    # @param [Symbol<:server, :session, :window>] kind Which options to operate on
    # @param [Server, Session, Window] target The target to operate
    #   on. Should be an instance of {Server} for global options
    # @param [Boolean] global Operate on global options?
    def initialize(kind, target, global = false)
      @kind   = kind
      @global = global
      @target = target
    end

    # Calls block once for each option.
    #
    # @yield [option, value]
    # @yieldparam [String] option Name of the option
    # @yieldparam [Object] value Value of the option
    # @return [OptionsList] self
    def each
      get_matching(//).each do |key, value|
        yield [key, value]
      end
      self
    end

    # @param [Regexp] The regexp which all returned option names have
    #   to match
    # @param [Boolean, nil] global Operate on global options? Inherits from @global if nil
    # @return [Hash<String, Object>] Returns a hash of all options
    #   that match `regexp`, and their values.
    # @api private
    def get_matching(regexp, global = nil)
      option_lines = server.invoke_command("show-options #{argument_string(global)}").each_line.select { |line|
        line =~ /^#{regexp}/
      }

      values = {}
      option_lines.each do |option_line|
        option, value   = option_line.chomp.split(" ", 2)
        mapping = Options::Mapping[option]
        value   = mapping ? mapping.from_tmux(value) : value
        values[option] = value
      end

      values
    end

    # Returns the value of an option. If the OptionsList does not
    # operate on global options, but the requested option could not be
    # found locally, it will be searched for globally, obeying option
    # inheritance of Tmux.
    #
    # @param [String] option Name of the option
    # @return [Object]
    def get(option)
      value = get_matching(option).values.first
      if value.nil? && !@global
        return get_matching(option, true).values.first
      else
        value
      end
    end

    # Sets an option.
    #
    # @param [String] option Name of the option
    # @param [Object] value New value of the option. Will
    #   automatically be converted to a string valid to Tmux.
    # @return [Object] `value`
    # @raise [RuntimeError] Raised if the new value is invalid
    def set(option, value)
      mapping = Options::Mapping[option]
      value = mapping.to_tmux(value) if mapping
      ret = server.invoke_command "set-option #{argument_string} #{option} \"#{value}\""
      if ret =~ /^value is invalid:/
        raise RuntimeError, ret
      end
      value
    end

    # Unsets an option. Note: global options cannot be unset.
    #
    # @param [String] option Name of the option
    # @raise [RuntimeError] Raised if you try to unset a global option.
    # @return [void]
    def unset(option)
      raise RuntimeError, "Cannot unset global option" if @global
      server.invoke_command "set-option #{argument_string(nil, ["-u"])} #{option}"
    end

    # Unknown methods will be treated as {#get getters} and {#set
    # setters} for options. Dashes in option names have to be replaced
    # with underscores.
    #
    # @return [void]
    def method_missing(m, *args)
      option = m.to_s.tr("_", "-")
      if option[-1..-1] == "="
        option = option[0..-2]
        set(option, args.first)
      else
        get(option)
      end
    end

    # @return [String, nil]
    # @api private
    def kind_flag
      {
        :server  => "-s",
        :session => nil,
        :window  => "-w",
      }[@kind]
    end
    private :kind_flag

    # @param [Boolean, nil] global Operate on global options? Inherits from @global if nil
    # @param [Array<String>] inject Flags to inject into the argument string
    # @return [String]
    # @api private
    def argument_string(global = nil, inject = [])
      global = @global if global.nil?
      flags = []
      flags << "-g" if global
      flags << kind_flag
      flags.concat inject
      flags << "-t #{@target.identifier}" if !global && @target && !@target.is_a?(Server)

      flags.compact.join(" ")
    end
    private :argument_string

    # @return [Server]
    def server
      @target.server
    end
    private :server
  end
end
