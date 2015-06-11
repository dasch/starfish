module Starfish
  class Event

    # Creates a new Event.
    #
    # name:         - The Symbol name of the event.
    # aggregate_id: - The String UUID of the aggregate this event happened to.
    # data:         - The Hash of data describing the event.
    #
    # Returns a new Event.
    def self.create(name, **options)
      new(name, options.merge(id: SecureRandom.uuid, timestamp: Time.now))
    end

    attr_reader :name, :id, :aggregate_id, :timestamp, :data

    def initialize(name, id:, aggregate_id:, timestamp:, data:)
      @name = name
      @id = id
      @aggregate_id = aggregate_id
      @timestamp = timestamp
      @data = data
    end
  end
end
