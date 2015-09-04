require 'starfish/kubernetes/build_job'

describe Starfish::Kubernetes::BuildJob do
  it "starts a build job in the cluster" do
    kubernetes_url = 'http://localhost:8080/api/'
    kubernetes = Kubeclient::Client.new(kubernetes_url)
    repository = "https://github.com/dasch/dummy.git"
    commit_id = "0961385c6ae031f96b909dfd2887790913684bea"

    build_job = described_class.new(
      kubernetes: kubernetes,
      repository: repository,
      commit_id: commit_id
    )

    build_job.start

    expect(build_job.status).to eq :succeeded
  end
end
