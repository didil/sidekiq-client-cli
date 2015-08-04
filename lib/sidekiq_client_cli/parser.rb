require 'cli'

class SidekiqClientCLI
  class Parser
    def parse
      CLI.new do
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
  end
end