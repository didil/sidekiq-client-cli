require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SidekiqClientCLI do
  before(:each) do
    @client = SidekiqClientCLI.new
  end

  describe "ARGV parsing" do
    it "fails if no command" do
      out = IOHelper.stderr_read do
        ARGV = []
        expect {
          @client.parse
        }.to (raise_error(SystemExit))
      end

      out.should include("'command' not given")
    end

    it "fails if wrong command" do
      out = IOHelper.stderr_read do
        ARGV = %w(dosomething)
        expect {
          @client.parse
        }.to (raise_error(SystemExit))
      end

      out.should include("Invalid command")
    end

    it "fails if push without classes" do
      out = IOHelper.stderr_read do
        ARGV = %w(push)
        expect {
          @client.parse
        }.to (raise_error(SystemExit))
      end

      out.should include("No Worker Classes")
    end

    it "parses push with classes" do
      worker_klasses = %w{FirstWorker SecondWorker}
      ARGV = %w{ push }.concat(worker_klasses)
      @client.parse
      @client.settings.command.should eq "push"
      @client.settings.command_args.should eq worker_klasses
      @client.settings.config_path.should eq SidekiqClientCLI::DEFAULT_CONFIG_PATH
    end

    it "parses push with classes" do
      worker_klasses = %w{FirstWorker SecondWorker}
      ARGV = %w{ -c mysidekiq.conf push }.concat(worker_klasses)
      @client.parse
      @client.settings.command.should eq "push"
      @client.settings.command_args.should eq worker_klasses
      @client.settings.config_path.should eq "mysidekiq.conf"
    end

  end

  describe "run" do

    it "loads the config file if existing and runs the command" do
      config_path = "sidekiq.conf"
      @client.settings.stub(:config_path).and_return(config_path)
      @client.settings.stub(:command).and_return("mycommand")
      @client.should_receive(:mycommand)

      File.should_receive(:exists?).with(config_path).and_return true
      @client.should_receive(:load).with(config_path)

      @client.run
    end

    it "loads the config file if existing and runs the command" do
      config_path = "sidekiq.conf"
      settings = double("settings")
      settings.stub(:config_path).and_return(config_path)
      settings.stub(:command).and_return("mycommand")

      @client.settings = settings
      @client.should_receive(:mycommand)

      File.should_receive(:exists?).with(config_path).and_return false
      @client.should_not_receive(:load)

      @client.run
    end

  end

  describe 'push' do
    it "pushes the worker classes" do
      klass1 = "FirstWorker"
      klass2 = "SecondWorker"
      settings = double("settings")
      settings.stub(:command_args).and_return [klass1, klass2]
      @client.settings = settings

      Sidekiq::Client.should_receive(:push).with('class' => klass1, 'args' => [])
      Sidekiq::Client.should_receive(:push).with('class' => klass2, 'args' => [])

      @client.push
    end

    it "prints and continues if an exception is raised" do
      klass1 = "FirstWorker"
      klass2 = "SecondWorker"
      settings = double("settings")
      settings.stub(:command_args).and_return [klass1, klass2]
      @client.settings = settings

      Sidekiq::Client.should_receive(:push).with('class' => klass1, 'args' => []).and_raise
      Sidekiq::Client.should_receive(:push).with('class' => klass2, 'args' => [])

      out = IOHelper.stdout_read do
        @client.push
      end
      out.should include("Failed to push")
    end

  end

end
