require 'sidekiq'
require 'cli'
require_relative 'sidekiq_client_cli/version'

class SidekiqClientCLI
  COMMANDS = %w{push}
  DEFAULT_CONFIG_PATH = "config/initializers/sidekiq.rb"

  attr_accessor :settings

  def initialize

  end

  def parse
    @settings = CLI.new do
      option :config_path, :short => :c, :default => DEFAULT_CONFIG_PATH, :description => "Sidekiq client config file path"
      argument :command, :description => "'push' to push a job to the queue"
      arguments :command_args, :required => false, :description => "command arguments"
    end.parse! do |settings|
      fail "Invalid command '#{settings.command}'. Available commands: #{COMMANDS.join(',').chomp(',')}" unless COMMANDS.include? settings.command

      if settings.command == "push" && settings.command_args.empty?
        fail "No Worker Classes to push"
      end
    end
  end

  def run
    # load the config file
    load settings.config_path if File.exists? settings.config_path

    self.send settings.command.to_sym
  end

  def push
    settings.command_args.each do |arg|
      begin
        jid = Sidekiq::Client.push('class' => arg, 'args' => [])
        p "Posted #{arg} to queue, Job ID : #{jid}"
      rescue StandardError => ex
        p "Failed to push to queue : #{ex.message}"
      end
    end
  end
end

