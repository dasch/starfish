require 'starfish/kubernetes/build_job'

describe Starfish::Kubernetes::BuildJob do
  it "starts a build job in the cluster" do
    kubernetes_url = 'http://localhost:8080/api/'
    kubernetes = Kubeclient::Client.new(kubernetes_url)
    repository = "https://github.com/dasch/dummy.git"
    sha = "0961385c6ae031f96b909dfd2887790913684bea"

    project = double(:project, repo_url: repository)
    pipeline = double(:pipeline, project: project)
    build = double(:build, image_tag: "test", sha: sha, pipeline: pipeline)
    build_job = described_class.new(kubernetes: kubernetes, build: build)

    build_job.start

    expect(build_job.status).to eq :succeeded
  end
end
