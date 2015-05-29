module Starfish
  class RollbackEvent
    attr_reader :target_release

    def initialize(target_release:)
      @target_release = target_release
    end
  end
end
