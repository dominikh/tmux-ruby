require "tmux/window/status/state"

module Tmux
  class Window
    # the "tab" in the statusbar
    class Status
      # @return [State]
      attr_reader :normal
      # @return [State]
      attr_reader :current
      # @return [State]
      attr_reader :alert
      def initialize(window)
        @window = window
        @normal  = State.new(@window,  :normal)
        @current = State.new(@window, :current)
        @alert   = State.new(@window,   :alert)
      end
    end
  end
end
