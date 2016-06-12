module Starfish
  class Environment
    attr_reader :name, :channels

    def initialize(name:)
      @name = name
      @channels = []
    end

    def to_s
      @name
    end
  end
end
