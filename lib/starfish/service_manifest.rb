require 'json'
require 'base64'

module Starfish
  class ServiceManifest
    class Process
      attr_reader :name, :command

      def initialize(name:, command:)
        @name = name
        @command = command
      end
    end

    def initialize(project, branch:, github_token:)
      @project = project
      @branch = branch
      @github_token = github_token
    end

    def processes
      manifest.map {|name, cmd| Process.new(name: name, command: cmd) }
    end

    private

    def manifest
      @manifest ||= load_manifest
    end

    def load_manifest
      file = github.contents(@project.repo, path: "Procfile", ref: @branch)
      parse(Base64.decode64(file.content))
    rescue Octokit::NotFound
      Hash.new
    end

    def parse(data)
      data
        .split("\n")
        .map {|line| line.split(":", 2) }
        .to_h
    end

    def github
      @github ||= Octokit::Client.new(
        access_token: @github_token
      )
    end
  end
end
