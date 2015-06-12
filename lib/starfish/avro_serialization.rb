module Starfish
  module AvroSerialization
    module ClassMethods
      def attributes(*attrs)
        @attributes ||= []
        @attributes.concat(attrs)
        @attributes
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def as_avro
      self.class.attributes.inject({}) do |hsh, attr|
        hsh.merge!(attr.as_avro => send(attr).as_avro)
      end
    end
  end
end
