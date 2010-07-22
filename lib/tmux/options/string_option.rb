require "tmux/options/option"
module Tmux
  module Options
    # @api private
    # @see Option
    class StringOption < Option
      class << self
        # @param (see Option.from_tmux)
        # @return [String, Symbol]
        # @api private
        # @see Option.from_tmux
        def from_tmux(value)
          super || value.gsub(/^"|"$/, "")
        end

        # @param (see Option.to_tmux)
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          super || value.inspect.gsub(/^"|"$/, "")
        end
      end
    end
  end
end
