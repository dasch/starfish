FROM ruby:2.2-onbuild

CMD bundle exec rackup --host 0.0.0.0 --port 80
