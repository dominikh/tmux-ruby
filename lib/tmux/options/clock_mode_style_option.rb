require "tmux/options/symbol_option"
module Tmux
  module Options
    # @api private
    # @see Option
    class ClockModeStyleOption < SymbolOption
      class << self
        # @param (see Option.from_tmux)
        # @return [Symbol]
        # @api private
        # @see Option.from_tmux
        def from_tmux(value)
          super || {12 => :twelve, 24 => :twenty_four}[value]
        end

        # @param [Symbol<:twelve, :twenty_four>] value
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          raise ArgumentError unless [:twelve, :twenty_four].include?(value)
          super
        end
      end
    end
  end
end
