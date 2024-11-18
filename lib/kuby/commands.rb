# typed: false

require 'kuby/version'
require 'gli'

# run the pre hook for the help command
GLI::Commands::Help.skips_pre = false

module Kuby
  class Commands
    # extend T::Sig
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
      # extend T::Sig

      # T::Sig::WithoutRuntime.sig { params(args: T::Array[String]).void }
      def run(args)
        if idx = args.index('rails') || idx = args.index('rake')
          # @rails_options = T.let(@rails_options, T.nilable(T::Array[String]))
          @rails_options = args[(idx + 1)..-1]
          super(args[0..idx])
        else
          @rails_options = []
          super
        end
      end
    end)

    # T::Sig::WithoutRuntime.sig { returns(Kuby::Tasks) }
    def self.tasks
      Kuby::Tasks.new(Kuby.environment)
    end

    # T::Sig::WithoutRuntime.sig {
    #   params(
    #     global_options: T::Hash[T.any(String, Symbol), T.any(String, Integer)]
    #   ).void
    # }
    def self.load_kuby_config!(global_options)
      return if @kuby_config_loaded

      Kuby.env = global_options[:environment] if global_options[:environment]
      Kuby.load!(global_options[:config])
      @kuby_config_loaded = true
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

    command_missing do |command_name, global_options|
      load_kuby_config!(global_options)
      cmd = nil

      # command_name is also the name of the plugin
      if plugin_klass = Kuby.plugins.find(command_name)
        if plugin_klass.respond_to?(:install_commands)
          desc "Run commands for the #{command_name} plugin."
          cmd = command(command_name) do |c|
            # the plugin now defines its own commands on c
            plugin_klass.install_commands(c)
          end
        end
      end

      cmd
    end

    pre do |global_options, options, args|
      load_kuby_config!(global_options)

      Kuby.plugins.each do |plugin_name, plugin_klass|
        if plugin_klass.respond_to?(:commands) && !@commands[plugin_name]
          desc "Run commands for the #{plugin_name} plugin."
          command plugin_name.to_sym do |c|
            plugin_klass.commands(c)
          end
        end
      end

      # GLI will abort unless this block returns a truthy value
      true
    end

    desc 'Builds Docker images.'
    command :build do |c|
      c.desc 'Docker build argument.'
      c.flag [:a, :arg], required: false, multiple: true

      c.desc 'When enabled, ignores missing build arguments.'
      c.switch [:'ignore-missing-args'], required: false, default_value: false

      c.desc 'Build only the images associated with the specified identifier(s). '\
             'Run `kuby images` for a list of all valid identifiers (note that '\
             'identifiers can be associated with more than one image).'
      c.flag [:only], required: false, multiple: true

      c.desc 'The directory to use as the Docker build context.'
      c.flag [:c, :context], required: false

      c.desc 'Pull the latest images from the registry and reuse any previously built layers.'
      c.switch [:l, :'cache-from-latest'], required: false, default_value: true

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
          context: options[:context],
          cache_from_latest: options[:'cache-from-latest']
        )
      end
    end

    desc 'Pushes Docker images to their associated registries.'
    command :push do |c|
      c.desc 'Push only the images associated with the specified identifier(s). '\
             'Run `kuby images` for a list of all valid identifiers (note that '\
             'identifiers can be associated with more than one image).'
      c.flag [:only], required: false, multiple: true
      c.action do |global_options, options, args|
        tasks.push(only: options[:only])
      end
    end

    desc 'Gets your Kubernetes cluster ready to run your Rails app.'
    command :setup do |c|
      c.desc 'Run the setup routines for only the specified plugin identifier(s).'
      c.flag [:only], required: false, multiple: true
      c.action do |global_options, options, args|
        tasks.setup(only: options[:only])
      end
    end

    desc 'Prints the effective Dockerfiles used to build Docker images.'
    command :dockerfiles do |c|
      c.desc 'Print Dockerfiles for only the images associated with the specified '\
             'identifier(s).'
      c.flag [:only], required: false, multiple: true
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

    desc 'Rolls back to the previous release.'
    command :rollback do |c|
      c.action do |global_options, options, args|
        tasks.rollback
      end
    end

    desc 'Prints the effective Kubernetes resources that will be applied on deploy.'
    command :resources do |c|
      c.desc 'Only print resources of the given kind.'
      c.flag [:K, :kind], required: false

      c.desc 'Only print resources that match the given name.'
      c.flag [:N, :name], required: false

      c.action do |global_options, options, args|
        tasks.print_resources(options[:kind], options[:name])
      end
    end

    desc 'Prints out the contents of the kubeconfig file Kuby is using to communicate '\
         'with your cluster.'
    command :kubeconfig do |c|
      c.action do |global_options, options, args|
        tasks.print_kubeconfig
      end
    end

    desc 'Prints out the URLs to the latest Docker images in the Docker registry.'
    command :images do |c|
      c.action do |global_options, options, args|
        tasks.print_images
      end
    end

    desc 'Runs an arbitrary kubectl command.'
    command :kubectl do |c|
      c.desc 'Prefixes the kubectl command with the namespace associated with '\
             'the current environment. For example, if the Kuby env is "production", '\
             'this option will prefix the kubectl command with "-n myapp-production".'
      c.switch [:N, :namespaced], default_value: false
      c.action do |global_options, options, args|
        if options[:namespaced]
          # sorry Demeter
          namespace = Kuby.definition.environment.kubernetes.namespace.metadata.name
          args = ['-n', namespace, *args]
        end

        tasks.kubectl(*args)
      end
    end

    desc 'Provides information about plugins.'
    command :plugin do |rc|
      rc.desc "Run a plugin's remove routine, i.e. uninstall it's resources from your cluster."
      rc.command :remove do |c|
        c.desc 'The plugin to remove. Run `kuby plugin list` for a list of valid plugin '\
               'identifiers.'
        c.flag [:p, :plugin], required: true
        c.action do |global_options, options, args|
          tasks.remove_plugin(options[:plugin])
        end
      end

      rc.desc 'List plugins.'
      rc.command :list do |c|
        c.desc 'Show all available plugins, not just the ones in use.'
        c.switch [:a, :all], default_value: false
        c.action do |global_options, options, args|
          tasks.list_plugins(all: options[:all])
        end
      end

      rc.desc "Run one of a plugin's rake tasks. Omit task names to print all tasks."
      rc.arg_name 'task_name', [:multiple, :optional]
      rc.command :rake do |c|
        c.action do |global_options, options, args|
          # Args come through as @rails_options here because of the monkeypatch
          # at the top of this file. Should revisit the patch at some point because
          # I think GLI's arg concept can replace it.
          if @rails_options.empty?
            tasks.list_rake_tasks
          else
            tasks.run_rake_tasks(@rails_options)
          end
        end
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
          tasks.remote_exec([*args, *@rails_options])
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
