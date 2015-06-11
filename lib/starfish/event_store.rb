require 'observer'
require 'starfish/event'

module Starfish
  class EventStore
    include Observable

    attr_reader :log

    def initialize(log:)
      @log = log
      @replay_mode = false
    end

    def record(event_name, aggregate_id:, **data)
      return if @replay_mode

      event = Event.create(event_name, aggregate_id: aggregate_id, data: data)

      @log.write(Marshal.dump(event))
      $logger.info "Stored event #{event.name}:\n#{data.inspect}"

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
