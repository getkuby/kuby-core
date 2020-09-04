require 'rouge'

module Kuby
  class Tasks
    attr_reader :environment

    def initialize(environment)
      @environment = environment
    end

    def print_dockerfile
      theme = Rouge::Themes::Base16::Solarized.new
      formatter = Rouge::Formatters::Terminal256.new(theme)
      lexer = Rouge::Lexers::Docker.new
      tokens = lexer.lex(Kuby.environment.docker.to_dockerfile.to_s)
      puts formatter.format(tokens)
    end

    def setup
      environment.kubernetes.setup
    end

    def build
      docker.cli.build(
        dockerfile: docker.to_dockerfile,
        image_url:  docker.metadata.image_url,
        tags:       docker.metadata.tags
      )
    end

    def run
      dockerfile = docker.to_dockerfile

      docker.cli.run(
        image_url: docker.metadata.image_url,
        tag:       'latest',
        ports:     dockerfile.exposed_ports
      )
    end

    def push
      hostname = docker.metadata.image_hostname

      unless docker.cli.auths.include?(hostname)
        Kuby.logger.info("Attempting to log in to registry at #{hostname}")

        begin
          docker.cli.login(
            url: docker.metadata.image_host,
            username: docker.credentials.username,
            password: docker.credentials.password
          )
        rescue Kuby::Docker::LoginError => e
          Kuby.logger.fatal("Couldn't log in to the registry at #{hostname}")
          Kuby.logger.fatal(e.message)
          return
        end
      end

      image_url = docker.metadata.image_url

      begin
        docker.tags.local.latest_tags.each do |tag|
          docker.cli.push(image_url, tag)
        end
      rescue Kuby::Docker::MissingTagError => e
        msg = "#{e.message} Run rake kuby:build to build the"\
          'Docker image before running this task.'

        Kuby.logger.fatal(msg)
        Kuby.logger.fatal(e.message)
      end
    end

    def deploy
      environment.kubernetes.deploy
    end

    def rollback
      environment.kubernetes.rollback
    end

    def print_resources
      kubernetes.before_deploy

      kubernetes.resources.each do |res|
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

    def remote_shell
      remote_exec(docker.distro_spec.shell_exe)
    end

    def remote_console
      remote_exec('bundle exec rails console')
    end

    def remote_dbconsole
      remote_exec('bundle exec rails dbconsole')
    end

    private

    def get_first_pod
      pods = kubernetes_cli.get_objects(
        'pods', namespace, match_labels.serialize
      )

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

    def kubernetes
      Kuby.environment.kubernetes
    end

    def docker
      Kuby.environment.docker
    end
  end
end
