require 'open3'
require 'securerandom'

namespace :kuby do
  task dockerfile: :environment do
    puts Kuby.definition.docker.to_dockerfile
  end

  task build: :environment do
    definition = Kuby.definition

    uuid = SecureRandom.hex[0...8]
    image_name = definition.docker_image_name
    uuid_tag = "#{image_name}:#{uuid}"
    latest_tag = "#{image_name}:latest"
    cmd = "docker build -t #{uuid_tag} -t #{latest_tag} -f- ."

    Open3.pipeline_w(cmd) do |stdin, _wait_threads|
      stdin.puts definition.docker.to_dockerfile
    end
  end

  task run: :environment do
    definition = Kuby.definition
    image_name = definition.docker_image_name
    df = definition.docker.to_dockerfile

    cmd = [
      'docker', 'run',
      '-e', 'RAILS_ENV=production',
      *df.exposed_ports.flat_map { |port| ['-p', "#{port}:#{port}"] },
      '--init',
      '--rm',
      "#{image_name}:latest"
    ]

    exec cmd.join(' ')
  end
end
