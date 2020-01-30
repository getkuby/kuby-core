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

      def apply(object, dry_run: false)
        cmd = [executable, 'apply', '--validate']
        cmd << '--dry-run' if dry_run
        cmd += ['-f', '-']

        open3_w(env, cmd) do |stdin, _wait_thread|
          stdin.puts(object.to_resource.to_yaml)
        end
      end

      def get(type, namespace, selector)
        cmd = [executable, '-n', namespace, 'get', type, '--selector']
        cmd << selector.map { |k, v| "#{k}=#{v}" }.join(',')
        cmd += ['-o', 'json']
        JSON.parse(backticks(cmd))
      end

      private

      def env
        @env ||= {
          'KUBECONFIG' => kubeconfig_path
        }
      end

      def status_key
        :kuby_k8s_cli_last_status
      end
    end
  end
end
