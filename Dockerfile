FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN wget -P /root/src http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz
RUN cd /root/src; tar xvf ruby-2.1.5.tar.gz
RUN cd /root/src/ruby-2.1.5; ./configure; make install

RUN gem update --system
RUN gem install bundler

RUN mkdir /app
WORKDIR /app

# Snappy dependencies.
RUN apt-get install -y --force-yes libsnappy1 libsnappy-dev

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --deployment

ADD . /app

EXPOSE 80
CMD bundle exec rackup --host 0.0.0.0 --port 80
