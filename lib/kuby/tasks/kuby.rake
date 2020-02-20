require 'colorized_string'
require 'rouge'

namespace :kuby do
  task dockerfile: :environment do
    theme = Rouge::Themes::Base16::Solarized.new
    formatter = Rouge::Formatters::Terminal256.new(theme)
    lexer = Rouge::Lexers::Docker.new
    tokens = lexer.lex(Kuby.definition.docker.to_dockerfile.to_s)
    puts formatter.format(tokens)
  end

  task build: :environment do
    docker = Kuby.definition.docker

    docker.cli.build(
      dockerfile: docker.to_dockerfile,
      image_url:  docker.metadata.image_url,
      tags:       docker.metadata.tags
    )
  end

  task run: :environment do
    docker = Kuby.definition.docker
    dockerfile = docker.to_dockerfile

    docker.cli.run(
      image_url: docker.metadata.image_url,
      tag:       'latest',
      env:       { 'RAILS_ENV' => 'production' },
      ports:     dockerfile.exposed_ports
    )
  end

  task push: :environment do
    docker = Kuby.definition.docker
    image_url = docker.metadata.image_url

    begin
      docker.latest_tags.each do |tag|
        docker.cli.push(image_url, tag)
      end
    rescue Kuby::Docker::MissingTagError => e
      msg = "#{e.message} Run rake kuby:build to build the"\
        'Docker image before running this task.'

      puts ColorizedString[msg].red
    end
  end

  task resources: :environment do
    Kuby.definition.kubernetes.resources.each do |res|
      puts res.to_resource.serialize.to_yaml
    end
  end

  task deploy: :environment do
    Kuby.definition.kubernetes.deploy
  end

  task rollback: :environment do
    Kuby.definition.kubernetes.rollback
  end

  task kubeconfig: :environment do
    path = Kuby.definition.kubernetes.provider.kubeconfig_path
    puts ColorizedString["Printing contents of #{path}"].yellow
    puts File.read(path)
  end

  task setup: :environment do
    Kuby.definition.kubernetes.provider.setup
  end

  task logs: :environment do
    kubernetes = Kuby.definition.kubernetes
    kubernetes_cli = kubernetes.provider.kubernetes_cli
    kubernetes_cli.logtail(
      kubernetes.namespace.name, kubernetes.deployment.selector.serialize
    )
  end
end
