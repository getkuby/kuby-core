# typed: strict

require 'kube-dsl'

module Kuby
  module Kubernetes
    class BareMetalProvider < Provider
      extend T::Sig

      DEFAULT_STORAGE_CLASS = T.let('hostpath'.freeze, String)

      class Config
        extend ::KubeDSL::ValueFields

        value_fields :kubeconfig
        value_fields :storage_class
      end

      T::Sig::WithoutRuntime.sig { returns(Config) }
      attr_reader :config

      T::Sig::WithoutRuntime.sig { params(environment: Environment).void }
      def initialize(environment)
        @config = T.let(Config.new, Config)
        super
      end

      T::Sig::WithoutRuntime.sig { params(block: T.proc.void).void }
      def configure(&block)
        config.instance_eval(&block) if block
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def kubeconfig_path
        config.kubeconfig
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def storage_class_name
        config.storage_class
      end

      private

      T::Sig::WithoutRuntime.sig { void }
      def after_initialize
        configure do
          # default kubeconfig path
          kubeconfig File.join(ENV['HOME'], '.kube', 'config')
          storage_class DEFAULT_STORAGE_CLASS
        end
      end
    end
  end
end
