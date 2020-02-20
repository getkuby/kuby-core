module Kuby
  module Kubernetes
    # "Global" means not just namespaced resources
    class DeployTask < ::Krane::DeployTask
      def initialize(kubeconfig_path, **options)
        @kubeconfig_path = kubeconfig_path
        super(**options)
      end

      private

      def kubeclient_builder
        @kubeclient_builder ||= ::Krane::KubeclientBuilder.new(
          kubeconfig: @kubeconfig_path
        )
      end
    end
  end
end
