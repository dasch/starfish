require 'starfish/repository'
require 'starfish/user'
require 'starfish/container_image'

$repo = Starfish::Repository.new

project = $repo.add_project(name: "Zendesk")
master = project.add_pipeline(name: "Master", branch: "master")
staging = project.add_pipeline(name: "Staging", branch: "staging")
production = project.add_pipeline(name: "Production", branch: "production")

users = [
  Starfish::User.new(name: "Luke Skywalker"),
  Starfish::User.new(name: "Darth Vader"),
  Starfish::User.new(name: "Princess Leia"),
  Starfish::User.new(name: "Han Solo"),
  Starfish::User.new(name: "Chewbacca"),
]

[master, staging, production].each do |pipeline|
  30.times do |number|
    commits = (1..5).to_a.sample.times.map {
      project.add_commit(
        sha: SecureRandom.hex,
        author: users.sample,
        additions: (0..100).to_a.sample,
        deletions: (0..100).to_a.sample
      )
    }

    image = Starfish::ContainerImage.new(id: SecureRandom.hex, namespace: "zendesk", name: "help_center")
    build = pipeline.add_build(commits: commits, image: image)
    build.add_status(name: "Travis CI", value: number > 28 ? :pending : :ok)
    build.add_status(name: "Code Climate", value: :ok)
    build.add_status(name: "System Tests", value: :ok)
  end
end

channels = []
channels << master.add_channel(name: "Master")
channels << staging.add_channel(name: "Staging")

%w(Pod1 Pod2 Pod3 Pod4 Pod5 Pod6).each do |channel_name|
  channels << production.add_channel(name: channel_name)
end

channels.each do |channel|
  env = {
    "NEW_RELIC_KEY" => "fads834rsd98basaf",
    "MYSQL_URL" => "mysql://fdsafs:fasdfsac@db.zdsys.com/production",
    "REDIS_URL" => "redis://redis1.zdsys.com/0",
  }

  config = channel.add_config(env: env)

  (8..11).to_a.sample.times do |number|
    build = channel.pipeline.find_build(number: (23..29).to_a.sample)
    channel.add_release(build: build, config: config)
  end
end
