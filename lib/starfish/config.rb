module Starfish
  class Config
    attr_reader :env, :version

    def initialize(env:, version:)
      @env = env
      @version = version
    end

    def to_s
      "v#{@version}"
    end
  end
end
