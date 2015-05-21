module Starfish
  class User
    attr_reader :name

    def initialize(name:)
      @name = name
    end

    def ==(other)
      name == other.name
    end

    def to_s
      name
    end
  end
end
