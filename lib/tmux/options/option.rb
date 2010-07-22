module Tmux
  module Options
    # This class is the base for all typecasting in ruby-tmux. It will
    # handle `default` and `none`. All other conversions have to be
    # done by classes inheriting from this one. You should never have
    # to instantiate or work with any of those classes yourself.
    #
    # @api private
    # @abstract
    class Option
      class << self
        # Takes an option value from tmux and converts it to an appropriate Ruby object.
        #
        # @param [String] value the value to cast
        # @return [Object, Symbol] Either the specific Ruby object, or either `:default` or `:none`
        # @api private
        # @see Subclasses
        def from_tmux(value)
          if [:default, :none].include?(value)
            return value.to_sym
          end
        end

        # Converts a Ruby object to a value for tmux.
        #
        # @param [Object] value the value to cast
        # @return [String]
        # @api private
        # @see Subclasses
        def to_tmux(value)
          if [:default, :none].include?(value)
            return value.to_s
          end
        end
      end
    end
  end
end
