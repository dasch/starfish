require 'observer'

module Starfish
  class EventStore
    include Observable

    Event = Struct.new(:name, :timestamp, :data)

    def initialize(log:)
      @log = log
      @offset = @log.size
    end

    def record(event_name, data = {})
      event = Event.new(event_name, Time.now, data)

      @log.write(event)
      $stderr.puts "Stored event #{event_name}:\n#{data.inspect}"

      changed
      notify_observers(event, @offset)

      @offset += 1
    end

    def empty?
      @log.empty?
    end

    def replay!
      @log.events.each_with_index do |event, offset|
        changed
        notify_observers(event, offset)
      end
    end

    def clear
      @log.clear
    end
  end
end
