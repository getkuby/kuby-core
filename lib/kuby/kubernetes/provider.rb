module Kuby
  module Kubernetes
    class Provider
      attr_reader :definition

      def initialize(definition)
        @definition = definition
        after_initialize
      end

      def configure(&block)
        # do nothing by default
      end

      def setup
        # do nothing by default
      end

      def deploy
        deployer.deploy
      end

      def rollback
        deployer.rollback
      end

      def kubernetes_cli
        @kubernetes_cli ||= Kuby::Kubernetes::CLI.new(kubeconfig_path)
      end

      def kubeconfig_path
        raise NotImplementedError, "please define #{__method__} in #{self.class.name}"
      end

      private

      def after_initialize
        # override this in derived classes
      end

      def deployer
        @deployer ||= Kuby::Kubernetes::Deployer.new(definition)
      end

      def spec
        definition.kubernetes
      end
    end
  end
end
