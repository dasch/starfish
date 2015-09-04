require 'starfish/kubernetes'

describe Starfish::Kubernetes::DeployJob do
  it "deploys to Kubernetes" do
    kubernetes_url = 'http://localhost:8080/api/'
    kubernetes = Kubeclient::Client.new(kubernetes_url)
    release = double(:release)

    job = described_class.new(
      kubernetes: kubernetes,
      release: release,
    )

    job.start
  end
end
