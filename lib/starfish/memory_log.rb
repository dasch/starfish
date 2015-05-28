module Starfish
  class MemoryLog
    def initialize
      @events = []
    end

    def write(event)
      @events << event
    end

    def events
      @events
    end

    def empty?
      @events.empty?
    end

    def clear
      @events.clear
    end
  end
end
