require "tmux/options/symbol_option"
module Tmux
  module Options
    # @api private
    # @see Option
    class JustificationOption < SymbolOption
      class << self
        # @param [Symbol<:left, :right, :centre, :default>] value
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          raise ArgumentError unless [:left, :right, :centre, :default].include?(value)
          super
        end
      end
    end
  end
end
