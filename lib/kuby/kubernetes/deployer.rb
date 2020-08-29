require 'fileutils'
require 'securerandom'
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
            "Validating global resource, #{res.kind_sym.to_s.humanize.downcase} '#{res.metadata.name}'"
          )

          cli.apply(res, dry_run: true)
        end

        resources.each do |res|
          Kuby.logger.info(
            "Deploying #{res.kind_sym.to_s.humanize.downcase} '#{res.metadata.name}'"
          )

          cli.apply(res)
        end
      rescue KubernetesCLI::InvalidResourceError => e
        Kuby.logger.fatal(e.message)
        Kuby.logger.fatal(e.resource.to_resource.to_yaml)
      end

      def deploy_namespaced_resources(resources)
        old_kubeconfig = ENV['KUBECONFIG']
        ENV['KUBECONFIG'] = provider.kubeconfig_path

        tmpdir = Dir.mktmpdir('kuby-deploy-resources')

        resources.each do |resource|
          resource_path = File.join(
            tmpdir, "#{SecureRandom.hex(6)}-#{resource.kind_sym.downcase}.yaml"
          )

          File.write(resource_path, resource.to_resource.to_yaml)
        end

        task = ::Kuby::Kubernetes::DeployTask.new(
          namespace: namespace.metadata.name,
          context: cli.current_context,
          filenames: [tmpdir]
        )

        task.run!(verify_result: true, prune: false)
      ensure
        ENV['KUBECONFIG'] = old_kubeconfig
        FileUtils.rm_rf(tmpdir)
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
