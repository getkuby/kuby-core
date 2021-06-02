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
