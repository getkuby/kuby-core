require 'open3'
require 'securerandom'
require 'colorized_string'

namespace :kuby do
  task dockerfile: :environment do
    puts Kuby.definition.docker.to_dockerfile
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

    # find latest tag
    images = Kuby.docker_cli.images(image_url)
    latest = images.find { |image| image[:tag] == 'latest' }

    unless latest
      msg = "Could not find tag 'latest'. Run rake kuby:build "\
        'to build the Docker image.'

      puts ColorizedString[msg].red
    end

    # find all tags that point to the same image as 'latest'
    images.each do |image_data|
      if image_data[:id] == latest[:id]
        Kuby.docker_cli.push(image_url, image_data[:tag])
      end
    end
  end
end
