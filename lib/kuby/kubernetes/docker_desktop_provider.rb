# typed: false
require 'kube-dsl'

module Kuby
  module Kubernetes
    class DockerDesktopProvider < Provider
      STORAGE_CLASS_NAME = 'hostpath'.freeze

      class Config
        extend ::KubeDSL::ValueFields

        value_fields :kubeconfig
      end

      attr_reader :config

      def configure(&block)
        config.instance_eval(&block) if block
      end

      # def after_configuration
      #   if rails_app = spec.plugin(:rails_app)
      #     # Remove ingress and change service type from ClusterIP to
      #     # LoadBalancer. No need to set up ingress for Docker Desktop
      #     # since it handles all the localhost mapping, etc if you set
      #     # up a service LB.
      #     rails_app.resources.delete(rails_app.ingress)
      #     rails_app.service.spec { type 'LoadBalancer' }
      #   end

      #   if assets = spec.plugin(:rails_assets)
      #     assets.service.spec { type 'LoadBalancer' }
      #   end
      # end

      def kubeconfig_path
        config.kubeconfig
      end

      def storage_class_name
        STORAGE_CLASS_NAME
      end

      private

      def after_initialize
        @config = Config.new

        configure do
          # default kubeconfig path
          kubeconfig File.join(ENV['HOME'], '.kube', 'config')
        end
      end
    end
  end
end
