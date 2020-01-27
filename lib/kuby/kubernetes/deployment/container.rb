module Kuby
  module Kubernetes
    class Deployment
      class Container
        extend ValueFields

        attr_reader :ports, :env_entries, :env_from_entries

        value_fields :name, :args, :command, :image, :image_pull_policy
        array_field(:port) { ContainerPort.new }
        array_field(:env, :env_entries) { EnvEntry.new }
        array_field(:env_from, :env_from_entries) { EnvFromEntry.new }

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            name: name,
            args: args,
            command: command,
            image: image,
            image_pull_policy: image_pull_policy,
            env: env_entries.map(&:serialize),
            envFrom: env_from_entries.map(&:serialize),
            ports: ports.map(&:serialize)
          }
        end
      end
    end
  end
end
