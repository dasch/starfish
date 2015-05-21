module Starfish
  class ContainerImage
    attr_reader :id, :namespace, :name

    def initialize(id:, namespace:, name:)
      @id, @namespace, @name = id, namespace, name
    end

    def to_s
      "#{namespace}/#{name}:#{id}"
    end
  end
end
