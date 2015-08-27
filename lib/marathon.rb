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
