require "tmux/options/symbol_option"
module Tmux
  module Options
    # @api private
    # @see Option
    class BellActionOption < SymbolOption
      class << self
        # @param (see Option.to_tmux)
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          raise ArgumentError unless [:any, :none, :current, :default].include?(value)
          super
        end
      end
    end
  end
end
