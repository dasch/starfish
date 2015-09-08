module Starfish
  class GithubSyncSubscriber
    def initialize(repo, importer:)
      @repo = repo
      @importer = importer
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def github_events_synchronized(timestamp, data)
      project_id = data.fetch(:project_id)
      event_id = data.fetch(:github_event_id)

      @importer.update_last_event_id(project_id: project_id, event_id: event_id)
    end
  end
end
