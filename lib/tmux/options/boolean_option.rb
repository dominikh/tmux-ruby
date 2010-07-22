require "tmux/options/option"
module Tmux
  module Options
    # @api private
    # @see Option
    class BooleanOption < Option
      class << self
        # @param (see Option.from_tmux)
        # @return [Boolean]
        # @api private
        # @see Option.from_tmux
        def from_tmux(value)
          super || value == "on"
        end

        # @param (see Option.to_tmux)
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          super || value ? "on" : "off"
        end
      end
    end
  end
end
