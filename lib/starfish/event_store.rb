require 'observer'
require 'starfish/marshal_event_serializer'

module Starfish
  class EventStore
    include Observable

    Event = Struct.new(:name, :timestamp, :data)

    attr_reader :log

    def initialize(log:, serializer: MarshalEventSerializer.new)
      @log = log
      @serializer = serializer
      @replay_mode = false
    end

    def record(event_name, data = {}, timestamp: Time.now)
      return if @replay_mode

      event = Event.new(event_name, timestamp, data)

      @log.write(@serializer.serialize(event))
      $stderr.puts "Stored event #{event_name}:\n#{data.inspect}"

      changed
      notify_observers(event)
    end

    def empty?
      @log.empty?
    end

    def replay!
      @replay_mode = true
      @log.events.each do |data|
        changed
        notify_observers(@serializer.deserialize(data))
      end
    ensure
      @replay_mode = false
    end

    def clear
      @log.clear
    end
  end
end
