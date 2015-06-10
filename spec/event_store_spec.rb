require 'starfish/event_store'

describe Starfish::EventStore do
  let(:event_store) { described_class.new }

  after do
    event_store.clear
  end

  describe "#write" do
    it "records events" do
      event_store.record(:seat_reserved, { seat: "32A" })
      event_store.record(:seat_reserved, { seat: "32B" })

      expect(event_store.events.map(&:data)).to eq [
        { seat: "32A" },
        { seat: "32B" },
      ]
    end

    it "allows rejecting events if other events have happened since the last version" do
      event_store.record(:seat_reserved, { seat: "32A" })

      expect {
        event_store.record(:seat_reserved, seat: "32A", if_version_equals: 0)
      }.to raise_error(Starfish::EventStore::ConcurrentWriteError)
    end
  end
end
