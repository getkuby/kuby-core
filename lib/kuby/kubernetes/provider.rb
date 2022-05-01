# typed: true

require 'kubernetes-cli'

module Kuby
  module Kubernetes
    class Provider
      attr_reader :environment

      def initialize(environment)
        @environment = environment
        after_initialize
      end

      def configure(&block)
        # do nothing by default
      end

      def setup
        # do nothing by default
      end

      # called after all providers and plugins have been configured
      def after_configuration
        # do nothing by default
      end

      # called before any providers or plugins have been setup
      def before_setup
        # do nothing by default
      end

      # called after all providers and plugins have been setup
      def after_setup
        # do nothing by default
      end

      # called before the deploy is initiated
      def before_deploy(manifest)
        # do nothing by default
      end

      # called after the deploy has completed
      def after_deploy(manifest)
        # do nothing by default
      end

      def deploy
        deployer.deploy
      end

      def rollback
        deployer.rollback
      end

      def kubernetes_cli
        @kubernetes_cli ||= ::KubernetesCLI.new(kubeconfig_path)
      end

      def helm_cli
        @helm_cli ||= ::HelmCLI.new(kubeconfig_path)
      end

      def kubeconfig_path
        raise NotImplementedError, "please define #{__method__} in #{self.class.name}"
      end

      def deployer
        @deployer ||= Kuby::Kubernetes::Deployer.new(environment)
      end

      private

      def after_initialize
        # override this in derived classes
      end

      def spec
        environment.kubernetes
      end
    end
  end
end
