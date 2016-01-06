init:
	bundle install --path vendor/bundle

lint:
	bundle exec rubocop

run:
	bundle exec ruby -Ilib ./bin/fdcli

build:
	gem build fdcli.gemspec

install:
	gem install fdcli*.gem

push:
	gem push fdcli*.gem
