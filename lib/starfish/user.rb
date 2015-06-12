module Starfish
  class User
    attr_reader :avatar_url, :username

    def initialize(name: nil, avatar_url: nil, username: nil)
      @name = name
      @avatar_url = avatar_url
      @username = username
    end

    def name
      @name || username
    end

    def ==(other)
      name == other.name
    end

    def to_s
      username || @name
    end

    def as_avro
      {
        name: name,
        username: username,
        avatar_url: avatar_url
      }.as_avro
    end
  end
end
