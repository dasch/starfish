require 'observer'
require 'starfish/redis_log'

module Starfish
  class EventStore
    include Observable

    Event = Struct.new(:name, :timestamp, :data)
    ConcurrentWriteError = Class.new(StandardError)

    attr_reader :log

    def initialize(log: RedisLog.new)
      @log = log
      @replay_mode = false
    end

    def record(event_name, if_version_equals: nil, **data)
      return if @replay_mode

      event = Event.new(event_name, Time.now, data)

      if @log.write(Marshal.dump(event), if_size_equals: if_version_equals)
        $logger.info "Stored event #{event_name}:\n#{data.inspect}"
      else
        raise ConcurrentWriteError
      end

      changed
      notify_observers(event)
    end

    def version
      @log.size
    end

    def events
      @log.events.map {|data| Marshal.load(data) }
    end

    def empty?
      @log.empty?
    end

    def replay!
      @replay_mode = true
      events.each do |event|
        changed
        notify_observers(event)
      end
    ensure
      @replay_mode = false
    end

    def clear
      @log.clear
    end
  end
end
