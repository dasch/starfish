module Starfish
  class Status
    attr_reader :name, :value

    def initialize(name:, value:)
      @name, @value = name, value
    end

    def ok?
      value == :ok
    end

    def pending?
      value == :pending
    end

    def failed?
      value == :failed
    end
  end
end
