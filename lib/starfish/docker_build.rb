module Starfish
  class DockerBuild
    attr_reader :image_id, :build_url

    def initialize(image_id:, build_url:, status:)
      @image_id = image_id
      @build_url = build_url
      @status = status
    end

    def success?
      @status == "succeeded"
    end
  end
end
