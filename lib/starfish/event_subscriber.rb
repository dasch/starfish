module Starfish
  class EventSubscriber
    def update(record)
      if respond_to?(record.name)
        event = record.name.to_s.camelize.constantize.new(record.data)
        send(record.name, record.timestamp, event)
      end
    end
  end
end
