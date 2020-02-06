require 'colorized_string'

module Kuby
  module Kubernetes
    class Deployer
      PRE_DEPLOY_ORDER = %i(namespace service_account config_map secret).freeze
      DEPLOY_ORDER = %i(service deployment ingress).freeze

      attr_reader :resources, :cli

      def initialize(resources, cli)
        @resources = resources
        @cli = cli
      end

      def deploy
        each_resource do |res|
          Kuby.logger.info(
            ColorizedString["Validating #{res.kind.to_s.humanize.downcase} '#{res.metadata.name}'"].yellow
          )

          validate_resource!(res)
        end

        Kuby.logger.info('All Kubernetes resources valid!')

        each_resource do |res|
          Kuby.logger.info(
            ColorizedString["Deploying #{res.kind.to_s.humanize.downcase} '#{res.metadata.name}'"].yellow
          )

          deploy_resource(res)
        end
      rescue InvalidResourceError => e
        Kuby.logger.fatal(ColorizedString[e.message].red)
        Kuby.logger.fatal(ColorizedString[e.resource.to_resource.to_yaml].red)
      end

      private

      def validate_resource!(res)
        cli.apply(res, dry_run: true)
      end

      def deploy_resource(res)
        cli.apply(res)
        Monitors.for(res, cli, timeout: 10.minutes).watch_until_ready
      end

      def each_resource(&block)
        examined = []

        PRE_DEPLOY_ORDER.each do |kind|
          each_resource_of_kind(kind) do |res|
            examined << res
            yield res
          end
        end

        unknown = (resources - examined).reject do |res|
          DEPLOY_ORDER.include?(res.kind)
        end

        unknown.map(&:kind).uniq.each do |unknown_kind|
          each_resource_of_kind(unknown_kind, &block)
        end

        DEPLOY_ORDER.each do |kind|
          each_resource_of_kind(kind, &block)
        end
      end

      def each_resource_of_kind(kind)
        resources.each do |res|
          yield res if res.kind == kind
        end
      end
    end
  end
end
