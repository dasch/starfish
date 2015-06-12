module Starfish
  class MarshalEventSerializer
    def serialize(event)
      Marshal.dump(event)
    end

    def deserialize(data)
      Marshal.load(data)
    end
  end
end
