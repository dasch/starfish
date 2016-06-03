module Starfish
  class Config
    class Null
      def env
        {}
      end

      def key?(key)
        false
      end

      def keys
        []
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

    def key?(key)
      @env.key?(key)
    end

    def fetch(key)
      @env.fetch(key)
    end

    def keys
      @env.keys
    end

    def to_s
      "v#{@version}"
    end
  end
end
