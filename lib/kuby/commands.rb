# typed: false

require 'kuby/version'
require 'gli'

module Kuby
  class Commands
    extend T::Sig
    extend GLI::App

    # GLI doesn't have a wildcard option, so it's impossible to tell it to
    # slurp up all args after a certain point. In our case, we want to be
    # able to invoke `rails` commands and pass through all the original
    # flags, switches, etc. To get around GLI's limitations, we identify
    # `rails` commands in this hijacked `run` method and only use GLI to
    # parse global options (like -e). The rest of the Rails options are
    # captured in an instance variable and thereby made available to the
    # Rails command handlers defined below. We use Module#prepend here to
    # avoid the usual series of cryptic alias_method calls (note that there
    # is no singleton class version of #prepend in the Ruby language).
    singleton_class.send(:prepend, Module.new do
      extend T::Sig

      sig { params(args: T::Array[String]).void }
      def run(args)
        if idx = args.index('rails') || idx = args.index('rake')
          @rails_options = T.let(@rails_options, T.nilable(T::Array[String]))
          @rails_options = args[(idx + 1)..-1]
          super(args[0..idx])
        else
          @rails_options = []
          super
        end
      end
    end)

    sig { returns(Kuby::Tasks) }
    def self.tasks
      Kuby::Tasks.new(Kuby.environment)
    end

    program_desc 'Kuby command-line interface. Kuby is a convention '\
      'over configuration approach for running Rails apps in Kubernetes.'

    version Kuby::VERSION

    subcommand_option_handling :normal
    arguments :loose

    desc 'The Kuby environment to use. Overrides KUBY_ENV.'
    flag [:e, :environment], type: String, required: false

    desc 'Path to your Kuby config file. Overrides KUBY_CONFIG.'
    default_value './kuby.rb'
    flag [:c, :config]

    pre do |global_options, options, args|
      Kuby.env = global_options[:environment] if global_options[:environment]
      Kuby.load!(global_options[:config])

      # GLI will abort unless this block returns a truthy value
      true
    end

    desc 'Builds the Docker image.'
    command :build do |c|
      c.flag [:a, :arg], required: false, multiple: true
      c.switch [:'ignore-missing-args'], required: false, default: false
      c.flag [:only], required: false
      c.flag [:c, :context], required: false
      c.action do |global_options, options, docker_args|
        build_args = {}.tap do |build_args|
          (options[:arg] || []).each do |a|
            key, value = a.split('=', 2)
            value = value[1..-2] if value.start_with?('"') || value.start_with?("'")
            build_args[key] = value
          end
        end

        tasks.build(
          build_args, docker_args,
          only: options[:only],
          ignore_missing_args: options[:'ignore-missing-args'],
          context: options[:context]
        )
      end
    end

    desc 'Pushes the Docker image to the configured registry.'
    command :push do |c|
      c.flag [:only], required: false
      c.action do |global_options, options, args|
        tasks.push(only: options[:only])
      end
    end

    desc 'Gets your Kubernetes cluster ready to run your Rails app.'
    command :setup do |c|
      c.action do |global_options, options, args|
        tasks.setup
      end
    end

    desc 'Prints the effective Dockerfiles used to build Docker images.'
    command :dockerfiles do |c|
      c.flag [:only], required: false
      c.action do |global_options, options, args|
        tasks.print_dockerfiles(only: options[:only])
      end
    end

    desc 'Deploys the application.'
    command :deploy do |c|
      c.desc 'The Docker tag to deploy. Defaults to the most recent tag.'
      c.flag [:t, :tag], required: false
      c.action do |global_options, options, args|
        tasks.deploy(options[:tag])
      end
    end

    desc 'Rolls back to the previous Docker tag.'
    command :rollback do |c|
      c.action do |global_options, options, args|
        tasks.rollback
      end
    end

    desc 'Prints the effective Kubernetes resources that will be applied on deploy.'
    command :resources do |c|
      c.flag [:K, :kind], required: false
      c.flag [:N, :name], required: false
      c.action do |global_options, options, args|
        tasks.print_resources(options[:kind], options[:name])
      end
    end

    desc 'Prints out the contents of the kubeconfig Kuby is using to communicate with your cluster.'
    command :kubeconfig do |c|
      c.action do |global_options, options, args|
        tasks.print_kubeconfig
      end
    end

    desc 'Runs an arbitrary kubectl command.'
    command :kubectl do |c|
      c.desc 'Prefixes the kubectl command with the namespace associated with '\
        'the current environment. For example, if the Kuby env is "production", '\
        'this option will prefix the kubectl command with "-n myapp-production".'
      c.switch [:N, :namespaced], default: false
      c.action do |global_options, options, args|
        if options[:namespaced]
          # sorry Demeter
          namespace = Kuby.definition.environment.kubernetes.namespace.metadata.name
          args = ['-n', namespace, *args]
        end

        tasks.kubectl(*args)
      end
    end

    desc 'Runs commands, etc against the Kubernetes cluster.'
    command :remote do |rc|
      rc.desc 'Tails (i.e. continuously streams) the Rails log from your running application.'
      rc.command :logs do |c|
        c.action do |global_options, options, args|
          tasks.remote_logs
        end
      end

      rc.desc 'Lists running Kubernetes pods.'
      rc.command :status do |c|
        c.action do |global_options, options, args|
          tasks.remote_status
        end
      end

      rc.desc 'Runs an arbitrary command inside a running Rails pod.'
      rc.command :exec do |c|
        c.action do |global_options, options, args|
          tasks.remote_exec([*args, *T.unsafe(@rails_options)])
        end
      end

      rc.desc 'Establishes a shell inside a running Rails pod.'
      rc.command :shell do |c|
        c.action do |global_options, options, args|
          tasks.remote_shell
        end
      end

      rc.desc 'Establishes a Rails console inside a running Rails pod.'
      rc.command :console do |c|
        c.action do |global_options, options, args|
          tasks.remote_console
        end
      end

      rc.desc 'Establishes a database console inside a running Rails pod.'
      rc.command :dbconsole do |c|
        c.action do |global_options, options, args|
          tasks.remote_dbconsole
        end
      end

      rc.desc "Restarts the Rails app's web pods."
      rc.command :restart do |c|
        c.action do |global_options, options, args|
          tasks.remote_restart
        end
      end
    end
  end
end
