require 'kube-dsl'

module Kuby
  module Kubernetes
    module Plugins
      class NginxIngress < Plugin
        class Config
          extend ::KubeDSL::ValueFields

          value_fields :provider
        end

        VERSION = '0.27.1'.freeze
        DEFAULT_PROVIDER = 'cloud-generic'.freeze
        NAMESPACE = 'ingress-nginx'.freeze
        SERVICE_NAME = 'ingress-nginx'.freeze

        SETUP_RESOURCES = [
          "https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-#{VERSION}/deploy/static/mandatory.yaml",
          "https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-#{VERSION}/deploy/static/provider/%{provider}.yaml"
        ].freeze

        def configure(&block)
          @config.instance_eval(&block) if block
        end

        def setup
          Kuby.logger.info('Deploying nginx ingress resources')

          SETUP_RESOURCES.each do |uri|
            uri = uri % { provider: @config.provider || DEFAULT_PROVIDER }
            kubernetes_cli.apply_uri(uri)
          end

          Kuby.logger.info('Nginx ingress resources deployed!')
        rescue => e
          Kuby.logger.fatal(e.message)
          raise
        end

        def namespace
          NAMESPACE
        end

        def service_name
          SERVICE_NAME
        end

        private

        def after_initialize
          @config = Config.new
        end

        def kubernetes_cli
          definition.kubernetes.provider.kubernetes_cli
        end
      end
    end
  end
end
