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

    def serialize(event)
      attrs = {
        "name" => event.name.to_s,
        "timestamp" => event.timestamp.to_i,
        "data" => Marshal.dump(event.data),
      }

      @avro.encode(attrs, schema_name: "event")
    end

    def deserialize(data)
      attrs = @avro.decode(data)

      EventStore::Event.new(
        attrs["name"].to_sym,
        Marshal.load(attrs["data"]),
        timestamp: Time.at(attrs["timestamp"])
      )
    end
  end
end
