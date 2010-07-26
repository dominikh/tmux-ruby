module Tmux
  module Exception
    class IndexInUse < RuntimeError
      def initialize(args)
        super "Index '%s' in session '%s' in use" % [args.last, args.first.identifier]
      end
    end
  end
end
