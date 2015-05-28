require 'observer'

module Starfish
  class EventStore
    include Observable

    Event = Struct.new(:name, :timestamp, :data)

    def initialize(log:)
      @log = log
    end

    def record(event_name, data = {})
      event = Event.new(event_name, Time.now, data)

      @log.write(event)
      $stderr.puts "Stored event #{event_name}:\n#{data.inspect}"

      changed
      notify_observers(event)
    end

    def empty?
      @log.empty?
    end

    def replay!
      @log.events.each do |event|
        changed
        notify_observers(event)
      end
    end

    def clear
      @log.clear
    end
  end
end
