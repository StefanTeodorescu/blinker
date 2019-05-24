FROM debian:stretch

RUN apt-get update -y
RUN apt-get -y install ruby ruby-dev build-essential supervisor cmake
RUN apt-get -y install postgresql-server-dev-9.6
RUN gem install fpm

COPY . .
RUN framework/package-blinker-framework.sh
RUN cd framework/llvm && mkdir build && cd build && ../create-tree-build.sh && bash release_build.sh && dpkg -i install/blinker-llvm_4.0.0*_amd64.deb

RUN platform/package-blinker-platform.sh

RUN apt-get install -y supervisor postgresql-server-dev-9.5
