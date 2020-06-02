require 'kube-dsl'

module Kuby
  module Kubernetes
    class MinikubeProvider < Provider
      class Config
        extend ::KubeDSL::ValueFields

        value_fields :kubeconfig
      end

      attr_reader :config

      def configure(&block)
        config.instance_eval(&block) if block
      end

      def kubeconfig_path
        config.kubeconfig
      end

      private

      def after_initialize
        @config = Config.new

        if rails_app = spec.plugin(:rails_app)
          # Remove ingress and change service type from ClusterIP to
          # LoadBalancer. No need to set up ingress for minikube since
          # it handles all the localhost mapping, etc if you set up a
          # service LB.
          rails_app.resources.delete(rails_app.ingress)
          rails_app.service.spec { type 'LoadBalancer' }
        end

        configure do
          # default kubeconfig path
          kubeconfig File.join(ENV['HOME'], '.kube', 'config')
        end
      end
    end
  end
end
