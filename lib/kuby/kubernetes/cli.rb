require 'json'
require 'open3'
require 'thread'

module Kuby
  module Kubernetes
    class CLI < CLIBase
      attr_reader :kubeconfig_path, :executable

      def initialize(kubeconfig_path, executable = nil)
        @kubeconfig_path = kubeconfig_path
        @executable = executable || `which kubectl`.strip
      end

      def apply(res, dry_run: false)
        cmd = [executable, '--kubeconfig', kubeconfig_path, 'apply', '--validate']
        cmd << '--dry-run' if dry_run
        cmd += ['-f', '-']

        open3_w(env, cmd) do |stdin, _wait_thread|
          stdin.puts(res.to_resource.to_yaml)
        end

        unless last_status.success?
          err = InvalidResourceError.new("Could not apply #{res.kind.to_s.humanize.downcase} "\
            "'#{res.name}': kubectl exited with status code #{last_status.exitstatus}"
          )

          err.resource = res
          raise err
        end
      end

      def apply_uri(uri, dry_run: false)
        cmd = [executable, '--kubeconfig', kubeconfig_path, 'apply', '--validate']
        cmd << '--dry-run' if dry_run
        cmd += ['-f', uri]
        systemm(cmd)

        unless last_status.success?
          err = InvalidResourceUriError.new("Could not apply #{uri}: "\
            "kubectl exited with status code #{last_status.exitstatus}"
          )

          err.resource_uri = uri
          raise err
        end
      end

      def get(type, namespace, selector)
        cmd = [executable, '--kubeconfig', kubeconfig_path, '-n', namespace]
        cmd += ['get', type, '--selector']
        cmd << selector.map { |k, v| "#{k}=#{v}" }.join(',')
        cmd += ['-o', 'json']
        result = backticks(cmd)

        unless last_status.success?
          raise GetResourceError, "couldn't get resources of type '#{type}' "\
            "in namespace #{namespace}: kubectl exited with status code #{last_status.exitstatus}"
        end

        JSON.parse(result)
      end

      def logs(namespace, selector, follow: true)
        cmd = [executable, '--kubeconfig', kubeconfig_path, '-n', namespace, 'logs']
        cmd << '-f' if follow
        cmd << '--selector'
        cmd << selector.map { |k, v| "#{k}=#{v}" }.join(',')
        execc(cmd)
      end

      private

      def env
        @env ||= {}
      end

      def status_key
        :kuby_k8s_cli_last_status
      end
    end
  end
end
