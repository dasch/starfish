module Starfish
  class EventSubscriber
    def update(record)
      if respond_to?(record.name)
        send(record.name, record.timestamp, record.event)
      end
    end
  end
end
