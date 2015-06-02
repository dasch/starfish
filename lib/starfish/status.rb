module Starfish
  class Status
    attr_reader :name, :value, :description, :created_at, :updated_at

    def initialize(name:, created_at:)
      @name = name
      @created_at = created_at
      @updated_at = created_at
      @description = name
      @value = :pending
    end

    def update(value, description:, timestamp:)
      @value = value
      @description = description
      @updated_at = timestamp
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

    def duration
      updated_at - created_at
    end
  end
end
