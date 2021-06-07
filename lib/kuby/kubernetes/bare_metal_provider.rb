# typed: strict

require 'kube-dsl'

module Kuby
  module Kubernetes
    class BareMetalProvider < Provider
      extend T::Sig

      STORAGE_CLASS_NAME = T.let('hostpath'.freeze, String)

      class Config
        extend ::KubeDSL::ValueFields

        value_fields :kubeconfig
      end

      sig { returns(Config) }
      attr_reader :config

      sig { params(environment: Environment).void }
      def initialize(environment)
        @config = T.let(Config.new, Config)
        super
      end

      sig { params(block: T.proc.void).void }
      def configure(&block)
        config.instance_eval(&block) if block
      end

      sig { returns(String) }
      def kubeconfig_path
        config.kubeconfig
      end

      sig { returns(String) }
      def storage_class_name
        STORAGE_CLASS_NAME
      end

      private

      sig { void }
      def after_initialize
        configure do
          # default kubeconfig path
          kubeconfig File.join(ENV['HOME'], '.kube', 'config')
        end
      end
    end
  end
end
