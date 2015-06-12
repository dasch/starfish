module Starfish
  class BaseAggregate
    NotFound = Class.new(StandardError)

    class << self
      def find(id)
        aggregates.fetch(id) { raise NotFound, "No aggregate with id #{id}" }
      end

      # Handle events.
      def update(event)
        puts "Handling event #{event.name} (#{event.aggregate_id})"
        aggregate = find_or_create(event.aggregate_id)
        aggregate.apply(event)
      end

      private

      def create(id)
        aggregates[id] = new
      end

      def find_or_create(id)
        aggregates[id] ||= new
      end

      def aggregates
        @aggregates ||= {}
      end
    end

    attr_reader :id

    def commit(event_name, aggregate_id: id, **data)
      $events.record(event_name, aggregate_id: aggregate_id, **data)
    end

    def apply(event)
      raise NotImplemented
    end
  end
end
