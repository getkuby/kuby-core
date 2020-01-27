require 'colorized_string'
require 'rouge'

namespace :kuby do
  task tester: :environment do
    Kuby.definition.kubernetes.service
  end

  task dockerfile: :environment do
    theme = Rouge::Themes::Base16::Solarized.new
    formatter = Rouge::Formatters::Terminal256.new(theme)
    lexer = Rouge::Lexers::Docker.new
    tokens = lexer.lex(Kuby.definition.docker.to_dockerfile.to_s)
    puts formatter.format(tokens)
  end

  task build: :environment do
    docker = Kuby.definition.docker

    Kuby.docker_cli.build(
      dockerfile: docker.to_dockerfile,
      image_url:  docker.metadata.image_url,
      tags:       docker.metadata.tags
    )
  end

  task run: :environment do
    docker = Kuby.definition.docker
    dockerfile = docker.to_dockerfile

    Kuby.docker_cli.run(
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
        Kuby.docker_cli.push(image_url, tag)
      end
    rescue Kuby::Docker::MissingTagError => e
      msg = "#{e.message} Run rake kuby:build to build the"\
        'Docker image before running this task.'

      puts ColorizedString[msg].red
    end
  end
end
