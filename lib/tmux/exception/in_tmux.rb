module Tmux
  module Exception
    class InTmux < RuntimeError
      def initialize(command)
        super("This command should not be run from inside tmux: #{command}")
      end
    end
  end
end
