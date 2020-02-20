require 'krane'
require 'tempfile'
require 'yaml'

module Kuby
  module Kubernetes
    class Deployer
      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end

      def deploy
        namespaced, global = all_resources.partition do |resource|
          # Unfortunately we can't use respond_to here because all KubeDSL
          # objects use ObjectMeta, which has a namespace field. Not sure
          # why, since it makes no sense for a namespace to have a namespace.
          # Instead we just check for nil here.
          resource.metadata.namespace
        end

        deploy_global_resources(global)
        deploy_namespaced_resources(namespaced)
      end

      private

      def deploy_global_resources(resources)
        resources.each do |res|
          Kuby.logger.info(
            ColorizedString["Validating global resource #{res.kind.to_s.humanize.downcase} '#{res.metadata.name}'"].yellow
          )

          cli.apply(res, dry_run: true)
        end

        resources.each do |res|
          Kuby.logger.info(
            ColorizedString["Deploying #{res.kind.to_s.humanize.downcase} '#{res.metadata.name}'"].yellow
          )

          cli.apply(res)
        end
      rescue InvalidResourceError => e
        Kuby.logger.fatal(ColorizedString[e.message].red)
        Kuby.logger.fatal(ColorizedString[e.resource.to_resource.to_yaml].red)
      end

      def deploy_namespaced_resources(resources)
        yaml = resources_to_yaml(resources)

        resources_file = Tempfile.new(['kuby-deploy-resources', '.yaml'])
        resources_file.write(yaml)
        resources_file.close

        task = DeployTask.new(
          provider.kubeconfig_path,
          namespace: namespace.metadata.name,
          context: cli.current_context,
          filenames: [resources_file.path]
        )

        task.run!(verify_result: true)
      ensure
        resources_file.close
        resources_file.unlink
      end

      def resources_to_yaml(resources)
        resources
          .map { |r| r.to_resource.to_yaml }
          .join("---\n")
      end

      def provider
        definition.kubernetes.provider
      end

      def namespace
        definition.kubernetes.namespace
      end

      def all_resources
        definition.kubernetes.resources
      end

      def cli
        provider.kubernetes_cli
      end
    end
  end
end
