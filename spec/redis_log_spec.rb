require 'starfish/redis_log'

describe Starfish::RedisLog do
  let(:log) { described_class.new(key: "test") }

  after do
    log.clear
  end

  describe "#write" do
    it "writes data to the log" do
      log.write("hello")

      expect(log.events).to eq ["hello"]
    end

    it "returns true on successful writes" do
      expect(log.write("hello")).to eq true
    end
  end
end
