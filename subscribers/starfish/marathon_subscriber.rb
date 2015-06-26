require 'excon'

class Marathon
  Error = Class.new(StandardError)
  URL = ENV.fetch("MARATHON_URL")

  def initialize
    headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
    }

    @connection = Excon.new(URL, headers: headers)
  end

  def create_or_update_app(id, config)
    if app_exist?(id)
      update_app(id, config)
    else
      create_app(id, config)
    end
  end

  def app_exist?(id)
    response = @connection.get(path: "/v2/apps/#{id}")
    response.status == 200
  end

  def update_app(id, config)
    put "/v2/apps/#{id}", config
  end

  def create_app(id, config)
    post "/v2/apps", config.merge(id: id)
  end

  private

  def get(path, payload = {})
    request(:get, path, payload)
  end

  def put(path, payload = {})
    request(:put, path, payload)
  end

  def post(path, payload = {})
    request(:post, path, payload)
  end

  def request(method, path, payload = {})
    response = @connection.request(method: method, path: path, body: payload.to_json)

    unless [200, 201].include?(response.status)
      raise Error, "Unexpected response status #{response.status}: #{response.body}"
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
      deploy(data[:release])
    end

    def build_automatically_released(timestamp, data)
      deploy(data[:release])
    end

    def config_change_released(timestamp, data)
      deploy(data[:release])
    end

    private

    def deploy(data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])
      release = channel.find_release(data[:id])

      app_id = "#{project.slug}-#{channel.slug}"

      configuration = {
        cmd: "",
        instances: 1,
        container: {
          type: "DOCKER",
          docker: {
            image: "docker-registry.zende.sk/starfish",
            forcePullImage: true,
            network: "HOST",
          },
        },
        env: release.config.env,
        force: true,
        constraints: [
          ["hostname", "CLUSTER", "mesos-slave1.pod99.aws1.zdsystest.com"]
        ],
        upgradeStrategy: {
          minimumHealthCapacity: 0
        }
      }

      begin
        marathon = Marathon.new

        $logger.info "Creating Marathon app #{app_id.inspect}..."
        app = marathon.create_or_update_app(app_id, configuration)
        $logger.info "Created app: #{app}"

        $events.record(:release_deployed, {
          release_id: release.id,
        })
      rescue Marathon::Error => e
        $events.record(:release_failed, {
          release_id: release.id,
          error: e.message,
        })

        $logger.error "Release failed: #{e}"
      end
    end
  end
end
