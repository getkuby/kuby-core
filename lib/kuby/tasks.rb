require 'rouge'

module Kuby
  class Tasks
    attr_reader :definition

    def initialize(definition)
      @definition = definition
    end

    def print_dockerfile
      theme = Rouge::Themes::Base16::Solarized.new
      formatter = Rouge::Formatters::Terminal256.new(theme)
      lexer = Rouge::Lexers::Docker.new
      tokens = lexer.lex(Kuby.definition.docker.to_dockerfile.to_s)
      puts formatter.format(tokens)
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
      image_url = docker.metadata.image_url

      begin
        docker.tags.local.latest_tags.each do |tag|
          docker.cli.push(image_url, tag)
        end
      rescue Kuby::Docker::MissingTagError => e
        msg = "#{e.message} Run rake kuby:build to build the"\
          'Docker image before running this task.'

        Kuby.logger.fatal(msg)
      end
    end

    def print_resources
      kubernetes.resources.each do |res|
        puts res.to_resource.serialize.to_yaml
      end
    end

    def print_kubeconfig
      path = kubernetes.provider.kubeconfig_path
      Kuby.logger.info("Printing contents of #{path}")
      puts File.read(path)
    end

    def remote_logs
      kubernetes_cli.logtail(namespace, match_labels.serialize)
    end

    def remote_status
      kubernetes_cli.run_cmd(['-n', namespace, 'get', 'pods'])
    end

    def remote_shell
      first_pod = get_first_pod
      shell = docker.distro_spec.shell_exe
      kubernetes_cli.exec_cmd(shell, namespace, first_pod.dig('metadata', 'name'))
    end

    def remote_console
      first_pod = get_first_pod

      kubernetes_cli.exec_cmd(
        'bundle exec rails console', namespace, first_pod.dig('metadata', 'name')
      )
    end

    def remote_dbconsole
      first_pod = get_first_pod

      kubernetes_cli.exec_cmd(
        'bundle exec rails dbconsole', namespace, first_pod.dig('metadata', 'name')
      )
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
      Kuby.definition.kubernetes
    end

    def docker
      Kuby.definition.docker
    end
  end
end
