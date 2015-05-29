module Starfish
  class ConfigChangedEvent
    attr_reader :key, :value

    def initialize(key:, value:)
      @key = key
      @value = value
    end
  end
end
