require 'spec_helper'
require 'starfish/github_event_importer'

describe Starfish::GithubEventImporter do
  it "imports Github events for the repository" do
    importer = described_class.new(
      repo: "dasch/starfish",
      last_event_id: "3115729852",
    )

    events = importer.start

    expect(events).to eq []
  end
end
