require 'avro_turf'

module Starfish
  class AvroEventSerializer
    def initialize
      @avro = AvroTurf.new(
        schemas_path: "./schemas",
        namespace: "starfish",
        codec: "deflate"
      )
    end

    def serialize(record)
      attrs = {
        "name" => record.name,
        "timestamp" => record.timestamp.to_i,
        "data" => serialize_event_data(record)
      }

      @avro.encode(attrs, schema_name: "event")
    end

    def deserialize(data)
      attrs = @avro.decode(data, schema_name: "event")
      schema_name = "starfish.events.#{attrs['name']}"
      event_data = @avro.decode(attrs["data"], schema_name: schema_name)
      event = attrs["name"].camelize.constantize.new(event_data)

      EventStore::Record.new(
        attrs["name"],
        Time.at(attrs["timestamp"]),
        event,
      )
    end

    private

    def serialize_event_data(record)
      @avro.encode(record.event.as_avro, schema_name: "starfish.events.#{record.name}")
    end
  end
end
