module Kuby
  module Kubernetes
    module Monitors
      class Deployment
        attr_reader :deployment, :cli, :timeout

        def initialize(deployment, cli, timeout:)
          @deployment = deployment
          @cli = cli
          @timeout = timeout
        end

        def watch_until_ready
          start_time = Time.now

          loop do
            if (Time.now - start_time) >= timeout
              break
            end

            data = cli.get(
              :deployment,
              deployment.metadata.namespace,
              deployment.spec.selector.match_labels.serialize
            )

            all_available = data['items'].all? do |item|
              item['status']['availableReplicas'] == item['status']['replicas']
            end

            break if all_available

            sleep 5
          end
        end
      end
    end
  end
end
