module Starfish
  class Config
    attr_reader :env

    def initialize(env:)
      @env = env
    end
  end
end
