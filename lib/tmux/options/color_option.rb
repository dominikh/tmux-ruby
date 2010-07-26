# -*- coding: utf-8 -*-
require "tmux/options/symbol_option"
module Tmux
  module Options
    # @api private
    # @see Option
    class ColorOption < SymbolOption
      class << self
        # @param [Symbol<:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white, :colour0 – colour255, :default>] value
        # @return (see Option.to_tmux)
        # @see Option.to_tmux
        # @api private
        def to_tmux(value)
          if ![:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white, :default].include?(value) &&
              value !~ /^colour\d+$/
            raise ArgumentError
          end
          super
        end
      end
    end
  end
end
