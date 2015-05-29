module Starfish
  class AutomaticReleaseEvent
    attr_reader :build

    def initialize(build:)
      @build = build
    end
  end
end
