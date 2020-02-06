module Kuby
  module Kubernetes
    class MinikubeProvider
      class Config
        extend ValueFields

        value_fields :kubeconfig
      end

      attr_reader :definition, :config

      def initialize(definition)
        @definition = definition
        @config = Config.new

        # Remove ingress and change service type from ClusterIP to
        # LoadBalancer. No need to set up ingress for minikube since
        # it handles all the localhost mapping, etc if you set up a
        # service LB.
        kube_spec.resources.delete(kube_spec.ingress)
        kube_spec.service.spec { type 'LoadBalancer' }

        configure do
          # default kubeconfig path
          kubeconfig File.join(ENV['HOME'], '.kube', 'config')
        end
      end

      def configure(&block)
        config.instance_eval(&block) if block
      end

      def setup
        # do nothing
      end

      def deploy
        deployer.deploy
      end

      def kubernetes_cli
        @kubernetes_cli ||= Kuby::Kubernetes::CLI.new(kubeconfig_path)
      end

      def kubeconfig_path
        config.kubeconfig
      end

      private

      def deployer
        @deployer ||= Kuby::Kubernetes::Deployer.new(
          kube_spec.resources, kubernetes_cli
        )
      end

      def kube_spec
        definition.kubernetes
      end
    end
  end
end
