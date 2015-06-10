require 'logger'

ENV["STARFISH_EVENTS_KEY"] = "starfish.test.events"

$logger = Logger.new("log/test.log")
