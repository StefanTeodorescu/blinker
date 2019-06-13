FROM debian:buster

RUN apt-get update -y
RUN apt-get -y install ruby ruby-dev build-essential cmake
RUN apt-get -y install curl
RUN gem install fpm

COPY . ./blinker

RUN dpkg -i blinker/postgresql*
