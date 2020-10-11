# typed: strict

module Kuby
  class Spinner
    extend T::Sig

    PIECES = T.let(%w(- \\ | /).freeze, T::Array[String])
    INTERVAL = T.let(0.2, Float)  # seconds

    sig {
      params(
        message: String,
        block: T.proc.params(spinner: Spinner).void
      )
      .void
    }
    def self.spin(message, &block)
      yield new(message)
    end

    sig { returns(String) }
    attr_reader :message

    sig { returns(Symbol) }
    attr_reader :status

    sig { params(message: String).void }
    def initialize(message)
      @message = T.let(message, String)
      @status = T.let(:running, Symbol)
      @thread = T.let(Thread.new do
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
      end, Thread)
    end

    sig { void }
    def success
      @status = :success
      @thread.join
    end

    sig { void }
    def failure
      @status = :failure
      @thread.join
    end
  end

  class SetupTask
    extend T::Sig

    sig { returns(String) }
    attr_reader :message

    sig { returns(T.proc.void) }
    attr_reader :callable

    sig { params(message: String, callable: T.proc.void).void }
    def initialize(message, callable)
      @message = message
      @callable = callable
    end

    sig { void }
    def run
      callable.call
    end
  end

  class Pipe
    extend T::Sig

    sig { returns(Symbol) }
    attr_reader :name

    sig { returns(T.untyped) }
    attr_reader :cli

    sig { returns(StringIO) }
    attr_reader :out

    sig { returns(StringIO) }
    attr_reader :err

    sig { params(name: Symbol, cli: T.untyped).void }
    def initialize(name, cli)
      @name = T.let(name, Symbol)
      @cli = T.let(cli, T.untyped)
      @out = T.let(StringIO.new, StringIO)
      @err = T.let(StringIO.new, StringIO)
    end

    sig { params(block: T.proc.void).void }
    def wrap(&block)
      cli.with_pipes(out, err) do
        block.call
      end
    end

    sig { returns(T::Boolean) }
    def success?
      cli.last_status.nil? || cli.last_status.success?
    end
  end

  class Pipes
    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member(fixed: Pipe)

    sig { returns(T::Array[Pipe]) }
    attr_reader :pipes

    sig { returns(T.nilable(StandardError)) }
    attr_reader :ex

    sig { params(clis: T::Hash[Symbol, T.untyped]).returns(Pipes) }
    def self.build(clis)
      new(clis.map { |name, cli| Pipe.new(name, cli) })
    end

    sig { params(pipes: T::Array[Pipe]).void }
    def initialize(pipes)
      @ex = T.let(@ex, T.nilable(StandardError))
      @pipes = T.let(pipes, T::Array[Pipe])
    end

    sig {
      override.params(
        block: T.proc.params(package: Pipe).void
      )
      .void
    }
    def each(&block)
      pipes.each(&block)
    end

    sig { params(block: T.proc.void).void }
    def wrap(&block)
      do_wrap(pipes, &block)
    end

    sig { returns(T::Boolean) }
    def success?
      pipes.all?(&:success?) && !ex
    end

    private

    sig {
      params(
        remaining_pipes: T::Array[Pipe],
        block: T.proc.void
      )
      .void
    }
    def do_wrap(remaining_pipes, &block)
      if remaining_pipes.empty?
        begin
          yield
        rescue => e
          @ex = e
        end

        return
      end

      T.must(remaining_pipes[0]).wrap do
        do_wrap(T.must(remaining_pipes[1..-1]), &block)
      end
    end
  end

  class SetupTaskList
    extend T::Sig

    sig { returns(T::Array[SetupTask]) }
    attr_reader :tasks

    sig { returns T::Hash[Symbol, T.untyped] }
    attr_reader :clis

    sig { params(tasks: T::Array[SetupTask], clis: T::Hash[Symbol, T.untyped]).void }
    def initialize(tasks, clis)
      @tasks = tasks
      @clis = clis
    end

    sig { void }
    def run
      tasks.each do |task|
        pipes = Pipes.build(clis)

        Spinner.spin(task.message) do |spinner|
          pipes.wrap { task.run }

          if pipes.success?
            spinner.success
          else
            spinner.failure
            print_error(pipes.ex)

            pipes.each do |pipe|
              print_streams(pipe)
            end

            return false
          end
        end
      end

      true
    end

    private

    sig { params(pipe: Pipe).void }
    def print_streams(pipe)
      unless pipe.out.string.strip.empty?
        puts("========= #{pipe.name.upcase} STDOUT ========")
        puts pipe.out.string
      end

      unless pipe.err.string.strip.empty?
        puts("========= #{pipe.name.upcase} STDERR ========")
        puts pipe.err.string
      end
    end

    sig { params(ex: T.nilable(StandardError)).void }
    def print_error(ex)
      return unless ex
      puts("========= RUBY ERROR ========")
      puts(ex.message)
      puts(T.must(ex.backtrace).join("\n"))
    end
  end

  class DevSetup
    extend T::Sig

    sig { returns(Environment) }
    attr_reader :environment

    sig { params(environment: Environment).void }
    def initialize(environment)
      @environment = T.let(environment, Environment)
      @setup_tasks = T.let(@setup_tasks, T.nilable(T::Array[SetupTask]))
      @clis = T.let(@clis, T.nilable(T::Hash[Symbol, T.untyped]))
      @tasks = T.let(@tasks, T.nilable(Tasks))
    end

    sig { void }
    def run
      SetupTaskList.new(setup_tasks, clis).run
    end

    private

    sig { returns(T::Array[SetupTask]) }
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

    sig { returns(Kubernetes::Spec) }
    def kubernetes
      environment.kubernetes
    end

    sig { returns(Docker::Spec) }
    def docker
      environment.docker
    end

    sig { returns T::Hash[Symbol, T.untyped] }
    def clis
      @clis ||= {
        kubectl: kubernetes.provider.kubernetes_cli,
        helm: kubernetes.provider.helm_cli,
        krane: kubernetes.provider.deployer,
        docker: docker.cli,
        kuby: Kuby.logger
      }
    end

    sig { returns(Tasks) }
    def tasks
      @tasks ||= Kuby::Tasks.new(environment)
    end
  end
end
