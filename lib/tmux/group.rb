module Tmux
  class Group
    attr_reader :server
    attr_reader :number
    def initialize(server, number)
      @server = server
      @number = number
    end

    def ==(other)
      other.is_a?(self.class) && other.server == @server && other.number == @number
    end

    def eql?(other)
      self == other
    end

    def hash
      [@server, @number].hash
    end

    def sessions
      @server.sessions(group: self)
    end
  end
end
