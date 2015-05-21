module Starfish
  class User
    attr_reader :name, :avatar_url

    def initialize(name:, avatar_url:)
      @name = name
      @avatar_url = avatar_url
    end

    def ==(other)
      name == other.name
    end

    def to_s
      name
    end
  end
end
