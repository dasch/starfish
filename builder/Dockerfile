FROM ubuntu:15.10

RUN apt-get update && apt-get install -y apt-transport-https wget ssh git && apt-get clean

# This is for Docker 1.8+
# RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
# RUN echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /etc/apt/sources.list.d/docker.list

# We're still on Docker 1.6 though.
RUN wget https://get.docker.com/builds/Linux/x86_64/docker-1.6.0 && \
      chmod +x docker-1.6.0 && \
      mv docker-1.6.0 /usr/bin/docker

# Add GitHub to the list of trusted hosts.
RUN mkdir ~/.ssh && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

COPY build.sh /build.sh
