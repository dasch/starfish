module Starfish
  class ManualReleaseEvent
    attr_reader :build

    def initialize(build:)
      @build = build
    end
  end
end
