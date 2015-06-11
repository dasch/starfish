module Starfish
  class BaseAggregate
    NotFound = Class.new(StandardError)

    class << self
      def find(id)
        aggregates.fetch(id) { raise NotFound, "No aggregate with id #{id}" }
      end

      def create(id = SecureRandom.uuid)
        aggregates[id] = new
      end

      def find_or_create(id)
        aggregates[id] || create(id)
      end

      # Handle events.
      def update(event)
        aggregate = find_or_create(event.aggregate_id)
        aggregate.apply(event)
      end

      private

      def aggregates
        @aggregates ||= {}
      end
    end

    attr_reader :id

    def commit(event_name, **data)
      $events.record(event_name, aggregate_id: id, **data)
    end
  end
end
