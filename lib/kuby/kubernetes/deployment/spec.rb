module Kuby
  module Kubernetes
    class Deployment
      class Spec
        extend ValueFields

        value_fields :restart_policy, :service_account_name
        array_field(:container) { Container.new }
        array_field(:image_pull_secret) { ImagePullSecret.new }

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            containers: containers.map(&:serialize),
            imagePullSecrets: image_pull_secrets.map(&:serialize),
            restartPolicy: restart_policy,
            serviceAccountName: service_account_name
          }
        end
      end
    end
  end
end
