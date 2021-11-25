# typed: false
require 'rouge'

module Kuby
  class Tasks
    attr_reader :environment

    def initialize(environment)
      @environment = environment
    end

    def print_dockerfiles(only = nil)
      kubernetes.docker_images.each do |image|
        next if only && image.identifier != only

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

    def setup
      environment.kubernetes.setup
    end

    def build(build_args = {}, docker_args = [], only = nil)
      kubernetes.docker_images.each do |image|
        next if only && image.identifier != only

        image = image.new_version
        Kuby.logger.info("Building image #{image.image_url} with tags #{image.tags.join(', ')}")
        image.build(build_args, docker_args)
      end
    end

    def push(only = nil)
      kubernetes.docker_images.each do |image|
        next if only && image.identifier != only

        image = image.current_version
        Kuby.logger.info("Pushing image #{image.image_url} with tags #{image.tags.join(', ')}")
        push_image(image)
      end
    end

    def push_image(image)
      if image.credentials.username && !image.docker_cli.auths.include?(image.image_host)
        Kuby.logger.info("Attempting to log in to registry at #{image.image_host}")

        begin
          image.docker_cli.login(
            url: image.image_host,
            username: image.credentials.username,
            password: image.credentials.password
          )
        rescue Kuby::Docker::LoginError => e
          Kuby.logger.fatal("Couldn't log in to the registry at #{image.image_host}")
          Kuby.logger.fatal(e.message)
          return
        end
      end

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
