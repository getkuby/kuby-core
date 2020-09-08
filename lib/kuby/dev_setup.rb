module Kuby
  class Spinner
    PIECES = %w(- \\ | /).freeze
    INTERVAL = 0.2  # seconds

    def self.spin(message)
      yield new(message)
    end

    attr_reader :message, :status

    def initialize(message)
      @message = message
      @status = :running
      @thread = Thread.new do
        counter = 0

        while true
          case status
            when :running
              piece = PIECES[counter % PIECES.size]
              STDOUT.write "\r[#{piece}] #{message}"
              sleep INTERVAL
              counter += 1
            when :success
              STDOUT.write("\r[+] #{message}")
              break
            when :failure
              STDOUT.write("\r[×] #{message}")
              break
          end
        end

        puts
      end
    end

    def success
      @status = :success
      @thread.join
    end

    def failure
      @status = :failure
      @thread.join
    end
  end

  class SetupTask
    attr_reader :message, :callable

    def initialize(message, callable)
      @message = message
      @callable = callable
    end

    def run
      callable.call
    end
  end

  class Pipe
    attr_reader :cli, :out, :err, :ex

    def initialize(cli)
      @cli = cli
      @out = StringIO.new
      @err = StringIO.new
    end

    def wrap(&block)
      cli.with_pipes(out, err) do
        begin
          block.call
        rescue => e
          @ex = e
        end
      end
    end
  end

  class Pipes
    def initialize(clis)
      @clis = clis
    end

    def wrap(&block)
      do_wrap(clis, &block)
    end

    private

    def do_wrap(remaining_clis, &block)
      if remaining_clis.empty?
        yield
        return
      end

      do_wrap(remaining_clis[1..-1], &block)
    end
  end

  class SetupTaskList
    attr_reader :tasks, :clis

    def initialize(tasks, clis)
      @tasks = tasks
      @clis = clis
    end

    def run
      tasks.each do |task|
        Spinner.spin(task.message) do |spinner|
          if with_hidden_output(clis) { task.run }
            spinner.success
          else
            spinner.failure
            return false
          end
        end
      end

      true
    end

    private

    def with_hidden_output(clis, &block)
      if clis.empty?
        begin
          yield
        rescue StopIteration
          return false
        end

        return true
      end

      out = StringIO.new
      err = StringIO.new
      cli = clis.first

      cli.with_pipes(out, err) do
        with_hidden_output(clis[1..-1]) do
          ex = begin
            block.call
            nil
          rescue => e
            e
          end

          if ex.is_a?(StopIteration)
            print_streams(out, err)
            raise ex
          elsif ex || (cli.last_status && !cli.last_status.success?)
            puts "Command exited with non-zero status code or an error was raised"
            print_error(ex)
            print_streams(out, err)
            raise StopIteration
          end
        end
      end
    end

    def print_streams(out, err)
      unless out.string.strip.empty?
        puts("========= STDOUT ========")
        puts out.string
      end

      unless err.string.strip.empty?
        puts("========= STDERR ========")
        puts err.string
      end
    end

    def print_error(ex)
      return unless ex
      puts("========= RUBY ERROR ========")
      puts(ex.message)
      puts(ex.backtrace.join("\n"))
    end
  end

  class DevSetup
    attr_reader :environment

    def initialize(environment)
      @environment = environment
    end

    def run
      SetupTaskList.new(setup_tasks, clis).run
    end

    private

    def setup_tasks
      @setup_tasks ||= [
        SetupTask.new(
          'Building dev Docker image', -> { tasks.build }
        ),

        SetupTask.new(
          'Setting up local Kubernetes cluster', -> { tasks.setup }
        ),

        SetupTask.new(
          'Deploying dev environment', -> { tasks.deploy }
        ),

        SetupTask.new(
          'Installing bundler', -> {
            tasks.remote_system("gem install bundler -v #{Bundler::VERSION}")
          }
        ),

        SetupTask.new(
          'Installing bundled gems', -> { tasks.remote_system('bundle install') }
        ),

        SetupTask.new(
          'Installing Javascript packages', -> { tasks.remote_system('yarn install') }
        ),

        SetupTask.new(
          'Creating database', -> { tasks.remote_system('bundle exec rake db:create') }
        ),

        SetupTask.new(
          'Migrating database', -> { tasks.remote_system('bundle exec rake db:migrate') }
        )
      ]
    end

    def kubernetes
      environment.kubernetes
    end

    def docker
      environment.docker
    end

    def clis
      @clis ||= [
        kubernetes.provider.kubernetes_cli,
        kubernetes.provider.helm_cli,
        kubernetes.provider.deployer,
        docker.cli,
        Kuby.logger
      ]
    end

    def tasks
      @tasks ||= Kuby::Tasks.new(environment)
    end
  end
end
