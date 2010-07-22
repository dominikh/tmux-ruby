module Tmux
  module Exception
    # Raised if a version requirement isn't met
    class UnsupportedVersion < BasicException
      # @param [String] version The required version
      def initialize(version = nil)
        if message
          version = "Required tmux version: #{version}"
        end

        super
      end
    end
  end
end
