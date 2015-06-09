require 'observer'

module Starfish
  class EventStore
    include Observable

    Event = Struct.new(:name, :timestamp, :data)

    attr_reader :log

    def initialize(log:)
      @log = log
      @replay_mode = false
    end

    def record(event_name, data = {})
      return if @replay_mode

      event = Event.new(event_name, Time.now, data)

      @log.write(Marshal.dump(event))
      $logger.info "Stored event #{event_name}:\n#{data.inspect}"

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
        notify_observers(Marshal.load(data))
      end
    ensure
      @replay_mode = false
    end

    def clear
      @log.clear
    end
  end
end
