require 'colorized_string'

module Kuby
  module Kubernetes
    class InvalidResourceError < StandardError
      attr_accessor :object
    end

    class Deployer
      PRE_DEPLOY_ORDER = %i(namespace service_account config_map secret).freeze
      DEPLOY_ORDER = %i(service deployment ingress).freeze

      attr_reader :objects, :cli

      def initialize(objects, cli)
        @objects = objects
        @cli = cli
      end

      def deploy
        each_object do |obj|
          Kuby.logger.info(
            ColorizedString["Validating #{obj.kind.to_s.humanize.downcase} '#{obj.name}'"].yellow
          )

          validate_object!(obj)
        end

        Kuby.logger.info('All Kubernetes resources valid!')

        each_object do |obj|
          Kuby.logger.info(
            ColorizedString["Deploying #{obj.kind.to_s.humanize.downcase} '#{obj.name}'"].yellow
          )

          deploy_object(obj)
        end
      rescue InvalidResourceError => e
        Kuby.logger.fatal(ColorizedString[e.message].red)
        Kuby.logger.fatal(ColorizedString[e.object.to_resource.to_yaml].red)
      end

      private

      def validate_object!(obj)
        cli.apply(obj, dry_run: true)

        unless cli.last_status.success?
          err = InvalidResourceError.new("Could not validate #{obj.kind.to_s.humanize.downcase} "\
            "'#{obj.name}': kubectl exited with status code #{cli.last_status.exitstatus}"
          )

          err.object = obj
          raise err
        end
      end

      def deploy_object(obj)
        cli.apply(obj)
        Monitors.for(obj, cli, timeout: 10.minutes).watch_until_ready
      end

      def each_object(&block)
        examined = []

        PRE_DEPLOY_ORDER.each do |kind|
          each_object_of_kind(kind) do |obj|
            examined << obj
            yield obj
          end
        end

        unknown = (objects - examined).reject do |obj|
          DEPLOY_ORDER.include?(obj.kind)
        end

        unknown.map(&:kind).uniq.each do |unknown_kind|
          each_object_of_kind(unknown_kind, &block)
        end

        DEPLOY_ORDER.each do |kind|
          each_object_of_kind(kind, &block)
        end
      end

      def each_object_of_kind(kind)
        objects.each do |obj|
          yield obj if obj.kind == kind
        end
      end
    end
  end
end
