require 'avro_turf'

[String, Numeric, TrueClass, FalseClass, NilClass].each do |klass|
  klass.class_eval do
    def as_avro
      self
    end
  end
end

class Symbol
  def as_avro
    to_s
  end
end

class Array
  def as_avro
    map(&:as_avro)
  end
end

class Hash
  def as_avro
    new_hash = {}
    each {|key, value| new_hash[key.as_avro] = value.as_avro }
    new_hash
  end
end

class Time
  def as_avro
    iso8601
  end
end

module Starfish
  class AvroEventSerializer
    def initialize
      @avro = AvroTurf.new(
        schemas_path: "./schemas",
        namespace: "starfish",
        codec: "deflate"
      )
    end

    def serialize(event)
      attrs = {
        "name" => event.name.to_s,
        "timestamp" => event.timestamp.to_i,
        "data" => serialize_event_data(event)
      }

      @avro.encode(attrs, schema_name: "event")
    end

    def deserialize(data)
      attrs = @avro.decode(data, schema_name: "event")
      schema_name = "starfish.events.#{attrs['name']}"
      event_data = @avro.decode(attrs["data"], schema_name: schema_name)

      EventStore::Event.new(
        attrs["name"].to_sym,
        Time.at(attrs["timestamp"]),
        event_data.with_indifferent_access
      )
    end

    private

    def serialize_event_data(event)
      @avro.encode(event.data.as_avro, schema_name: "starfish.events.#{event.name}")
    end
  end
end
