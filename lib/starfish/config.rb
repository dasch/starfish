module Starfish
  class Config
    class Null
      def env
        {}
      end

      def version
        0
      end

      def to_s
        "v0"
      end
    end

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
