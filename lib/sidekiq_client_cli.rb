require 'sidekiq'
require 'cli'
require_relative 'sidekiq_client_cli/version'

class SidekiqClientCLI
  COMMANDS = %w{push}
  DEFAULT_CONFIG_PATH = "config/initializers/sidekiq.rb"

  attr_accessor :settings

  def parse
    @settings = CLI.new do
      option :config_path, :short => :c, :default => DEFAULT_CONFIG_PATH, :description => "Sidekiq client config file path"
      option :queue, :short => :q, :description => "Queue to place job on"
      option :retry, :short => :r, :cast => lambda { |r| SidekiqClientCLI.cast_retry_option(r) }, :description => "Retry option for job"
      argument :command, :description => "'push' to push a job to the queue"
      arguments :command_args, :required => false, :description => "command arguments"
    end.parse! do |settings|
      fail "Invalid command '#{settings.command}'. Available commands: #{COMMANDS.join(',').chomp(',')}" unless COMMANDS.include? settings.command

      if settings.command == "push" && settings.command_args.empty?
        fail "No Worker Classes to push"
      end
    end
  end

  def self.cast_retry_option(retry_option)
    return true if !!retry_option.match(/^(true|t|yes|y)$/i)
    return false if !!retry_option.match(/^(false|f|no|n|0)$/i)
    return retry_option.to_i if !!retry_option.match(/^\d+$/)
  end

  def run
    # load the config file
    load settings.config_path if File.exists?(settings.config_path)

    # set queue or retry if they are not given
    settings.queue ||= Sidekiq.default_worker_options['queue']
    settings.retry ||= Sidekiq.default_worker_options['retry']

    self.send settings.command.to_sym
  end

  def push
    settings.command_args.each do |arg|
      begin
        jid = Sidekiq::Client.push({ 'class' => arg,
                                     'queue' => settings.queue,
                                     'args'  => [],
                                     'retry' => settings.retry })
        p "Posted #{arg} to queue '#{settings.queue}', Job ID : #{jid}, Retry : #{settings.retry}"
      rescue StandardError => ex
        p "Failed to push to queue : #{ex.message}"
      end
    end
  end

end
