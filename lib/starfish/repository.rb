require 'redis'
require 'starfish/project'

module Starfish
  class Repository
    REDIS_KEY = "starfish:state"

    attr_reader :projects

    def initialize
      @redis = Redis.new
      @projects = []
    end

    def persist!
      @redis.set(REDIS_KEY, Marshal.dump(@projects))
    end

    def load!
      data = @redis.get(REDIS_KEY)

      if data
        @projects = Marshal.load(data)
      end
    end

    def add_project(**options)
      project = Project.new(**options)
      @projects << project
      project
    end

    def find_project(slug:)
      projects.find {|p| p.slug == slug }
    end
  end
end
