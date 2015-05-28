require 'starfish/repository'
require 'starfish/user'
require 'starfish/container_image'

$repo = Starfish::Repository.new
$repo.load!

if ENV["RACK_ENV"] == "development"
  puts "=== BOOTSTRAPPING ==="

  users = ["Luke Skywalker", "Darth Vader", "Princess Leia", "Han Solo", "Chewbacca"].map {|name|
    avatar = "http://api.randomuser.me/portraits/thumb/%s/%s.jpg" % [%w(men women).sample, rand(40)]
    Starfish::User.new(
      name: name,
      avatar_url: avatar
    )
  }

  # Zendesk
  project = $repo.add_project(name: "Zendesk")
  master = project.add_pipeline(name: "Master", branch: "master")
  staging = project.add_pipeline(name: "Staging", branch: "staging")
  production = project.add_pipeline(name: "Production", branch: "production")

  last_good_build = (26..29).to_a.sample

  [master, staging, production].each do |pipeline|
    30.times do |number|
      commits = (1..5).to_a.sample.times.map {
        project.add_commit(
          sha: SecureRandom.hex,
          author: users.sample
        )
      }

      image = Starfish::ContainerImage.new(id: SecureRandom.hex, namespace: "zendesk", name: "help_center")
      build = pipeline.add_build(commits: commits, image: image, author: users.sample)
      build.add_status(name: "Travis CI", value: number.succ > last_good_build ? :pending : :ok)
      build.add_status(name: "Code Climate", value: :ok)
      build.add_status(name: "System Tests", value: :ok)
    end
  end

  channels = []
  channels << master.add_channel(name: "Master", auto_release_builds: true)
  channels << staging.add_channel(name: "Staging", auto_release_builds: true)

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

    1.upto((25..28).to_a.sample) do |number|
      build = channel.pipeline.find_build(number: number)
      channel.add_release(build: build, config: config)

      if rand < 0.2
        config = channel.add_config(env: env.dup.update("NEW_RELIC_KEY" => env["NEW_RELIC_KEY"].chars.shuffle.join("")))
        channel.add_release(build: build, config: config)
      end
    end
  end


  # Help Center
  project = $repo.add_project(name: "Help Center")
  production = project.add_pipeline(name: "Production", branch: "master")

  channels = %w(Master Staging Pod1 Pod2 Pod3 Pod4 Pod5 Pod6).map do |channel_name|
    production.add_channel(name: channel_name, auto_release_builds: !channel_name.include?("Pod"))
  end

  30.times do |number|
    commits = (1..5).to_a.sample.times.map {
      project.add_commit(
        sha: SecureRandom.hex,
        author: users.sample
      )
    }

    image = Starfish::ContainerImage.new(id: SecureRandom.hex, namespace: "zendesk", name: "help_center")
    build = production.add_build(commits: commits, image: image, author: users.sample)
    build.add_status(name: "Travis CI", value: number >= 28 ? :pending : :ok)
    build.add_status(name: "Code Climate", value: :ok)
    build.add_status(name: "System Tests", value: :ok)
  end

  channels.each do |channel|
    env = {
      "NEW_RELIC_KEY" => "fads834rsd98basaf",
      "MYSQL_URL" => "mysql://fdsafs:fasdfsac@db.zdsys.com/production",
      "REDIS_URL" => "redis://redis1.zdsys.com/0",
    }

    config = channel.add_config(env: env)

    unless channel.auto_release_builds?
      1.upto((25..28).to_a.sample) do |number|
        build = channel.pipeline.find_build(number: number)
        channel.add_release(build: build, config: config)

        if rand < 0.2
          config = channel.add_config(env: env.dup.update("NEW_RELIC_KEY" => env["NEW_RELIC_KEY"].chars.shuffle.join("")))
          channel.add_release(build: build, config: config)
        end
      end
    end
  end

  $repo.persist!
end
