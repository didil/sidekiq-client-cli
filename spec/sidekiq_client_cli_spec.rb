require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SidekiqClientCLI do
  let(:default_queue) { Sidekiq.default_worker_options['queue'] }
  let(:default_retry_option) { Sidekiq.default_worker_options['retry'] }

  before(:each) { @client = SidekiqClientCLI.new }

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
      @client.settings.queue.should eq nil
      @client.settings.retry.should eq nil
    end

    it "parses push with a configuration file" do
      worker_klasses = %w{FirstWorker SecondWorker}
      ARGV = %w{ -c mysidekiq.conf push }.concat(worker_klasses)
      @client.parse
      @client.settings.command.should eq "push"
      @client.settings.command_args.should eq worker_klasses
      @client.settings.config_path.should eq "mysidekiq.conf"
      @client.settings.queue.should eq nil
    end

    it "parses push with a queue" do
      worker_klasses = %w{FirstWorker SecondWorker}
      ARGV = %w{ -q my_queue push }.concat(worker_klasses)
      @client.parse
      @client.settings.command.should eq "push"
      @client.settings.command_args.should eq worker_klasses
      @client.settings.config_path.should eq SidekiqClientCLI::DEFAULT_CONFIG_PATH
      @client.settings.queue.should eq "my_queue"
    end

    it 'parses push with a boolean retry' do
      worker_klasses = %w{FirstWorker SecondWorker}
      ARGV = %w{ -r false push }.concat(worker_klasses)
      @client.parse
      @client.settings.command.should eq "push"
      @client.settings.command_args.should eq worker_klasses
      @client.settings.config_path.should eq SidekiqClientCLI::DEFAULT_CONFIG_PATH
      @client.settings.retry.should eq false
    end

    it 'parses push with an integer retry' do
      worker_klasses = %w{FirstWorker SecondWorker}
      ARGV = %w{ -r 42 push }.concat(worker_klasses)
      @client.parse
      @client.settings.command.should eq "push"
      @client.settings.command_args.should eq worker_klasses
      @client.settings.config_path.should eq SidekiqClientCLI::DEFAULT_CONFIG_PATH
      @client.settings.retry.should eq 42
    end

  end

  describe "run" do

    it "loads the config file if existing and runs the command" do
      config_path = "sidekiq.conf"
      @client.settings.stub(:config_path).and_return(config_path)
      @client.settings.stub(:command).and_return("mycommand")
      @client.settings.stub(:queue).and_return(default_queue)
      @client.settings.stub(:retry).and_return(default_retry_option)
      @client.should_receive(:mycommand)

      File.should_receive(:exists?).with(config_path).and_return true
      @client.should_receive(:load).with(config_path)

      @client.run
    end

    it "won't load a non-existant config file and the command is run" do
      config_path = "sidekiq.conf"
      settings = double("settings")
      settings.stub(:config_path).and_return(config_path)
      settings.stub(:command).and_return("mycommand")
      settings.stub(:queue).and_return(default_queue)
      settings.stub(:retry).and_return(default_retry_option)

      @client.settings = settings
      @client.should_receive(:mycommand)

      File.should_receive(:exists?).with(config_path).and_return false
      @client.should_not_receive(:load)

      @client.run
    end

    it "doesnt try to change the retry value if it has been set to false" do
      config_path = "sidekiq.conf"
      @client.settings.stub(:config_path).and_return(config_path)
      @client.settings.stub(:command).and_return("mycommand")
      @client.settings.stub(:queue).and_return(default_queue)
      @client.settings.stub(:retry).and_return(false)

      @client.should_receive(:mycommand)
      @client.should_not_receive(:retry=)

      @client.run
    end

    it "doesnt try to change the retry value if it has been set to true" do
      config_path = "sidekiq.conf"
      @client.settings.stub(:config_path).and_return(config_path)
      @client.settings.stub(:command).and_return("mycommand")
      @client.settings.stub(:queue).and_return(default_queue)
      @client.settings.stub(:retry).and_return(true)

      @client.should_receive(:mycommand)
      @client.should_not_receive(:retry=)

      @client.run
    end
  end

  describe 'push' do
    let(:settings) { double("settings") }
    let(:klass1) { "FirstWorker" }
    let(:klass2) { "SecondWorker" }
    let(:client) { SidekiqClientCLI.new }

    before(:each) do
      settings.stub(:command_args).and_return [klass1, klass2]
      client.settings = settings
    end

    it 'returns true if all #push_argument calls return true' do
      client.stub(:push_argument).and_return(true)
      client.push.should eq true
    end

    it 'returns false if at least one #push_argument call fails' do
      client.should_receive(:push_argument).with('FirstWorker').and_return(true)
      client.should_receive(:push_argument).with('SecondWorker').and_return(false)
      client.push.should eq false
    end
  end

  describe '#push_argument' do
    let(:settings) { double("settings", :queue => default_queue, :retry => default_retry_option) }
    let(:klass1) { "FirstWorker" }
    let(:client) { SidekiqClientCLI.new }

    before(:each) do
      client.settings = settings
    end

    it "pushes the worker classes" do
      Sidekiq::Client.should_receive(:push).with('class' => klass1,
                                                 'args' => [],
                                                 'queue' => default_queue,
                                                 'retry' => default_retry_option)

      client.__send__(:push_argument, klass1).should eq true
    end

    it "pushes the worker classes to the correct queue" do
      queue = "Queue"
      settings.stub(:queue).and_return queue

      Sidekiq::Client.should_receive(:push).with('class' => klass1,
                                                 'args' => [],
                                                 'queue' => queue,
                                                 'retry' => default_retry_option)

      client.__send__(:push_argument, klass1).should eq true
    end

    it 'pushes the worker classes with retry disabled' do
      retry_option = false
      settings.stub(:retry).and_return retry_option

      Sidekiq::Client.should_receive(:push).with('class' => klass1,
                                                 'args' => [],
                                                 'queue' => default_queue,
                                                 'retry' => retry_option)

      client.__send__(:push_argument, klass1).should eq true
    end

    it 'pushes the worker classes with a set retry number' do
      retry_attempts = 5
      settings.stub(:retry).and_return retry_attempts

      Sidekiq::Client.should_receive(:push).with('class' => klass1,
                                                 'args' => [],
                                                 'queue' => default_queue,
                                                 'retry' => retry_attempts)

      client.__send__(:push_argument, klass1).should eq true
    end

    it "prints and continues if an exception is raised" do
      Sidekiq::Client.should_receive(:push).with('class' => klass1,
                                                 'args' => [],
                                                 'queue' => default_queue,
                                                 'retry' => default_retry_option).and_raise

      out = IOHelper.stdout_read do
        client.__send__(:push_argument, klass1).should eq false
      end
      out.should include("Failed to push")
    end

  end

  describe 'cast_retry_option' do
    subject { SidekiqClientCLI }

    it 'returns false if the string matches false|f|no|n|0' do
      subject.cast_retry_option('false').should == false
      subject.cast_retry_option('f').should == false
      subject.cast_retry_option('no').should == false
      subject.cast_retry_option('n').should == false
      subject.cast_retry_option('0').should == false
    end

    it 'returns true if the string matches true|t|yes|y' do
      subject.cast_retry_option('true').should == true
      subject.cast_retry_option('t').should == true
      subject.cast_retry_option('yes').should == true
      subject.cast_retry_option('y').should == true
    end

    it 'returns an integer if the passed string is an integer' do
      subject.cast_retry_option('1').should == 1
      subject.cast_retry_option('42').should == 42
    end

  end

end
