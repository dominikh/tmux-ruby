require "tmux/options/option"
module Tmux
  module Options
    # @api private
    # @see Option
    class SymbolOption < Option
      class << self
        # @param (see Option.from_tmux)
        # @return [Symbol]
        # @api private
        # @see Option.from_tmux
        def from_tmux(value)
          super || value.to_sym
        end

        # @param (see Option.to_tmux)
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          super || value.to_s
        end
      end
    end
  end
end
