require 'observer'
require 'active_support/core_ext/hash/indifferent_access'
require 'starfish/avro_event_serializer'

module Starfish
  class EventStore
    include Observable

    Event = Struct.new(:name, :timestamp, :data)

    attr_reader :log

    def initialize(log:, serializer: AvroEventSerializer.new)
      @log = log
      @serializer = serializer
    end

    def record(event_name, data = {})
      event = Event.new(event_name, Time.now, data)
      data = @serializer.serialize(event)

      @log.write(data)
      $logger.info "Stored event #{event_name}:\n#{data.inspect}"

      changed
      notify_observers(@serializer.deserialize(data))
    end

    def empty?
      @log.empty?
    end

    def replay!
      @log.events.each do |data|
        changed
        notify_observers(@serializer.deserialize(data))
      end
    end

    def clear
      @log.clear
    end
  end
end
