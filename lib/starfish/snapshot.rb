require 'starfish/repository'
require 'snappy'

module Starfish
  class Snapshot
    REDIS_KEY = "starfish.snapshot"

    attr_reader :offset, :repo

    def initialize(offset:, repo:)
      @offset = offset
      @repo = repo
    end

    def save
      redis = Redis.new
      redis.set(REDIS_KEY, Snappy.deflate(Marshal.dump(self)))

      $logger.info "Saved snapshot at offset #{offset}"
    end

    def update(event)
      @offset += 1
    end

    def self.restore
      redis = Redis.new

      if data = redis.get(REDIS_KEY)
        snapshot = Marshal.load(Snappy.inflate(data))
        $logger.info "Loading snapshot at offset #{snapshot.offset}"
        snapshot
      else
        $logger.info "No snapshot found, starting from scratch"
        new(offset: 0, repo: Repository.new)
      end
    end
  end
end
