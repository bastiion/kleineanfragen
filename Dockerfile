FROM ruby:2.3.0

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql-client nodejs poppler-utils advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush pngquant

# enable utf8 in irb
ENV LANG C.UTF-8

RUN gem install bundler --version 1.14.6

RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

ADD . /app

EXPOSE 5000