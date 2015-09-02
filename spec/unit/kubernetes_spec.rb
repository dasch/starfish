require 'starfish/kubernetes'

describe Starfish::Kubernetes do
  describe "#deploy" do
    it "deploys to Kubernetes" do
      k8s = described_class.new

      release = double(:release)
      k8s.deploy(release)
    end
  end
end
