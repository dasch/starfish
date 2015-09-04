require 'starfish/kubernetes'

describe Starfish::Kubernetes::DeployJob do
  it "deploys to Kubernetes" do
    kubernetes_url = 'http://localhost:8080/api/'
    kubernetes = Kubeclient::Client.new(kubernetes_url)

    env = { "SOME_ENV_VAR" => "something" }
    config = double(:config, env: env)
    project = double(:project, slug: "test-app")
    pipeline = double(:pipeline, project: project)
    channel = double(:channel, pipeline: pipeline)
    build = double(:build, image_tag: "nginx")
    release = double(:release, build: build, channel: channel, config: config, to_s: "v1")

    job = described_class.new(
      kubernetes: kubernetes,
      release: release,
    )

    job.start
  end
end
