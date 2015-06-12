require 'starfish/avro_serialization'

module Starfish
  class User
    include AvroSerialization

    attr_reader :avatar_url, :username
    attributes :name, :username, :avatar_url

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
  end
end
