# sidekiq-client-cli

[![Build Status](https://secure.travis-ci.org/didil/sidekiq-client-cli.png)](http://travis-ci.org/didil/sidekiq-client-cli]) [![Code Climate](https://codeclimate.com/github/didil/sidekiq-client-cli.png)](https://codeclimate.com/github/didil/sidekiq-client-cli) [![Coverage Status](https://coveralls.io/repos/didil/sidekiq-client-cli/badge.png)](https://coveralls.io/r/didil/sidekiq-client-cli)

A command line client for Sidekiq
You can use this when you need to interact with Sidekiq via the command line, for example in cron jobs.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-client-cli'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-client-cli

## Dependencies

Requires sidekiq >= 2.15.0

## Usage

Push worker classes to Sidekiq :

    $ sidekiq-client push MyWorker OtherWorker

You can specify a sidekiq config file via the -c option (if not specified the usual rails path config/initializers/sidekiq.rb is used) :

    $ sidekiq-client -c mysidekiq.conf push MyWorker OtherWorker

You can also specify a specific queue to push the jobs to :

    $ sidekiq-client -q my_queue push MyWorker OtherWorker

You can specify that the job should not be retried, if it fails :

    $ sidekiq-client -r false push MyWorker OtherWorker

You can also specify the number of times a job should be retried, if it fails :

    $ sidekiq-client -r 5 push MyWorker OtherWorker

For help :

    $ sidekiq-client --help

## Contributing to sidekiq-client-cli

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Adil Haritah. See LICENSE.txt for further details.
