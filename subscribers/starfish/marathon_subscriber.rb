require 'excon'

class Marathon
  URL = ENV.fetch("MARATHON_URL")

  def initialize
    headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
    }

    @connection = Excon.new(URL, headers: headers)
  end

  def create_app(config)
    post "/v2/apps", config
  end

  private

  def post(path, payload = {})
    response = @connection.post(path: path, body: payload.to_json)

    if response.status != 201
      raise "Unexpected response status #{response.status}"
    end

    JSON.parse(response.body) unless response.body == "null"
  end
end

module Starfish
  class MarathonSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.data)
      end
    end

    def build_released(data)
      data = data[:release]
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])
      release = channel.find_release(data[:id])

      app_id = "/#{channel.slug}/#{project.slug}-#{pipeline.slug}"
      app_id = project.slug

      configuration = {
        id: app_id,
        cmd: "while true; do; echo yolo; sleep 10; done",
        instances: 1,
        container: {
          type: "DOCKER",
          docker: {
            image: "ubuntu:latest",
            network: "BRIDGE",
          },
        },
        force: true,
      }

      marathon = Marathon.new
      $logger.info "Creating Marathon app #{app_id.inspect}..."
      app = marathon.create_app(configuration)
      $logger.info "Created app: #{app}"
    end
  end
end
