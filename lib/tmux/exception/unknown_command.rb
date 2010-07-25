module Tmux
  module Exception
    class UnknownCommand < RuntimeError
      def initialize(command)
        super("unknown command: #{command}")
      end
    end
  end
end
