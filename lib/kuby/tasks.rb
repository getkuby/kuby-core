# typed: false
require 'rake'
require 'rouge'

module Kuby
  class Tasks
    attr_reader :environment

    def initialize(environment)
      @environment = environment
    end

    def print_dockerfiles(only: [])
      kubernetes.docker_images.each do |image|
        next unless only.empty? || only.include?(image.identifier)

        image = image.current_version
        identifier = image.identifier ? " ##{image.identifier}" : ""
        Kuby.logger.info("Dockerfile for#{identifier} image #{image.image_url} with tags #{image.tags.join(', ')}")
        theme = Rouge::Themes::Base16::Solarized.new
        formatter = Rouge::Formatters::Terminal256.new(theme)
        lexer = Rouge::Lexers::Docker.new
        tokens = lexer.lex(image.dockerfile.to_s)
        puts formatter.format(tokens)
      end
    end

    def setup(only: [])
      environment.kubernetes.setup(only: only.map(&:to_sym))
    end

    def remove_plugin(name)
      plugin = environment.kubernetes.plugin(name)

      # Allow running uninstallation procedures for plugins that are no longer part
      # of the environment. This is especially useful for plugins Kuby adds by default
      # in one version and removes in another, like KubeDB.
      plugin ||= if plugin_class = Kuby.plugins.find(name.to_sym)
        plugin_class.new(environment)
      end

      unless plugin
        Kuby.logger.fatal(
          "No plugin found named '#{name}'. Run `kuby plugin list -a` to show a list of all available plugins."
        )

        exit 1
      end

      plugin.remove
    end

    def list_plugins(all: false)
      Kuby.plugins.each do |name, _|
        if environment.kubernetes.plugins.include?(name)
          Kuby.logger.info("* #{name}")
        elsif all
          Kuby.logger.info("  #{name}")
        end
      end
    end

    def run_rake_tasks(tasks)
      if tasks.empty?
        Kuby.logger.fatal('Please specify at least one task to run.')
        exit 1
      end

      Kuby.load_rake_tasks!
      Rake::Task[tasks.join(' ')].invoke
    end

    def list_rake_tasks
      Kuby.load_rake_tasks!

      rows = Rake::Task.tasks.map do |task|
        [task.name, task.full_comment || '']
      end

      puts Kuby::Utils::Table.new(%w(NAME DESCRIPTION), rows).to_s
    end

    def build(build_args = {}, docker_args = [], only: [], ignore_missing_args: false, context: nil)
      check_platform(docker_args)

      if master_key = rails_app.master_key
        build_args['RAILS_MASTER_KEY'] = master_key
      end

      check_build_args(build_args) unless ignore_missing_args

      kubernetes.docker_images.each do |image|
        next unless only.empty? || only.include?(image.identifier)
        return unless perform_docker_login_if_necessary(image)

        image = image.new_version
        Kuby.logger.info("Building image #{image.image_url} with tags #{image.tags.join(', ')}")
        image.build(build_args, docker_args, context: context)
      end
    end

    def push(only: [])
      kubernetes.docker_images.each do |image|
        next unless only.empty? || only.include?(image.identifier)

        image = image.current_version
        Kuby.logger.info("Pushing image #{image.image_url} with tags #{image.tags.join(', ')}")
        push_image(image)
      end
    end

    def push_image(image)
      return unless perform_docker_login_if_necessary(image)

      begin
        image.tags.each { |tag| image.push(tag) }
      rescue Kuby::Docker::MissingTagError => e
        msg = "#{e.message} Run kuby build to build the "\
          'Docker images before running this task.'

        Kuby.logger.fatal(msg)
        Kuby.logger.fatal(e.message)
      end
    end

    def deploy(tag = nil)
      environment.kubernetes.deploy(tag)
    end

    def rollback
      environment.kubernetes.rollback
    end

    def print_resources(kind = nil, name_pattern = nil)
      kubernetes.before_deploy

      name_rxp = Regexp.new(name_pattern) if name_pattern

      kubernetes.resources.each do |res|
        next if kind && res.kind_sym.to_s != kind

        next if name_rxp && !name_rxp.match?(res.metadata.name)

        puts res.to_resource.serialize.to_yaml
      end
    end

    def print_kubeconfig
      path = kubernetes.provider.kubeconfig_path
      Kuby.logger.info("Printing contents of #{path}")
      puts File.read(path)
    end

    def print_images
      rows = kubernetes.docker_images.flat_map do |image|
        image = image.current_version

        image.tags.map do |tag|
          [image.identifier, "#{image.image_url}:#{tag}"]
        end
      end

      puts Kuby::Utils::Table.new(%w(IDENTIFIER URL), rows).to_s
    end

    def kubectl(*cmd)
      kubernetes_cli.run_cmd(cmd)
    end

    def remote_logs
      kubernetes_cli.logtail(namespace, match_labels.serialize)
    end

    def remote_status
      kubernetes_cli.run_cmd(['-n', namespace, 'get', 'pods'])
    end

    def remote_exec(cmd)
      first_pod = get_first_pod
      kubernetes_cli.exec_cmd(cmd, namespace, first_pod.dig('metadata', 'name'))
    end

    def remote_system(cmd)
      first_pod = get_first_pod
      kubernetes_cli.system_cmd(cmd, namespace, first_pod.dig('metadata', 'name'))
    end

    def remote_shell
      remote_exec(docker.distro_spec.shell_exe)
    end

    def remote_console
      remote_exec('bundle exec rails console')
    end

    def remote_dbconsole
      remote_exec('bundle exec rails dbconsole')
    end

    def remote_restart
      deployment = rails_app.deployment.metadata.name
      kubernetes_cli.restart_deployment(namespace, deployment)
    end

    private

    def check_platform(docker_args)
      arch, * = RUBY_PLATFORM.split('-')

      if arch != 'x86_64' && !docker_args.include?('--platform')
        Kuby.logger.fatal(<<~END)
          Hey there! It looks like your processor isn't x86-compatible.
          By default, Docker will try to build images that match the
          current architecture, in this case #{arch}. Most hosting
          providers run x86 hardware, meaning Docker images built using
          this computer's architecture might fail to run when deployed
          to production. You can fix this by running the build command
          with a special --platform flag, eg:

          bundle exec kuby -e production build -- --platform linux/amd64

          If you meant to build for the current architecture, you can
          prevent this error by passing the --platform argument for the
          current architecture, eg. --platform linux/arm64 for ARM, etc.
        END

        exit 1
      end
    end

    def check_build_args(build_args)
      required_args = kubernetes.docker_images.flat_map do |image|
        image.dockerfile.commands.flat_map do |command|
          case command
            when Kuby::Docker::Dockerfile::Arg
              command.args
            else
              []
          end
        end
      end

      required_args.uniq!

      if File.exist?(File.join('config', 'master.key'))
        required_args.delete('RAILS_MASTER_KEY')
      end

      missing_args = required_args - build_args.keys

      if missing_args.any?
        Kuby.logger.fatal(<<~END)
          The following Docker build arguments are missing: #{missing_args.join(', ')}.
          Please pass each argument to `kuby build` using the -a or --arg parameter (note
          that the -a/--arg parameter can be specified multiple times). For example:

          kuby build -a #{missing_args.first}=value ...

          To ignore missing build args, pass the --ignore-missing-args parameter.
        END

        exit 1
      end
    end

    def perform_docker_login_if_necessary(image)
      auth_uris = image.docker_cli.auths.map do |url|
        Kuby::Docker::DockerURI.parse_uri(url)
      end

      logged_in = image.credentials.username && (
        auth_uris.any? do |uri|
          image.image_hostname == uri.host ||
            image.registry_index_hostname == uri.host
        end
      )

      if !logged_in
        Kuby.logger.info("Attempting to log in to registry at #{image.image_host}")

        begin
          # For some reason, Docker login with a port doesn't work for some
          # registries (most notably Docker Hub). Since the default is 443 anyway,
          # it should be fine to omit it.
          url = if image.image_uri.has_default_port?
            image.image_hostname  # host without port
          else
            image.image_host      # host with port
          end

          image.docker_cli.login(
            url: url,
            username: image.credentials.username,
            password: image.credentials.password
          )
        rescue Kuby::Docker::LoginError => e
          Kuby.logger.fatal("Couldn't log in to the registry at #{image.image_host}")
          Kuby.logger.fatal(e.message)

          return false
        end
      end

      true
    end

    def get_first_pod
      pods = kubernetes_cli.get_objects(
        'pods', namespace, match_labels.serialize
      )

      # consider only "Running" pods that aren't marked for deletion
      pods.select! do |pod|
        pod.dig('status', 'phase') == 'Running' &&
          !pod.dig('metadata', 'deletionTimestamp')
      end

      if pods.empty?
        raise Kuby::Kubernetes::MissingResourceError,
          "Couldn't find any running pods in namespace '#{namespace}' :("

        exit 1
      end

      pods.first
    end

    def namespace
      kubernetes.namespace.metadata.name
    end

    def match_labels
      rails_app.deployment.spec.selector.match_labels
    end

    def rails_app
      kubernetes.plugin(:rails_app)
    end

    def kubernetes_cli
      kubernetes.provider.kubernetes_cli
    end

    def helm_cli
      kubernetes.provider.helm_cli
    end

    def docker_cli
      docker.cli
    end

    def kubernetes
      Kuby.environment.kubernetes
    end

    def docker
      Kuby.environment.docker
    end
  end
end
