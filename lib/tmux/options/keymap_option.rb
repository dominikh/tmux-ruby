require "tmux/options/symbol_option"
module Tmux
  module Options
    # @api private
    # @see Option
    class KeymapOption < SymbolOption
      class << self
        # @param (see Option.to_tmux)
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          raise ArgumentError unless [:emacs, :vi].include?(value)
          super
        end
      end
    end
  end
end
