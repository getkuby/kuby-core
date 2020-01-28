require 'open3'
require 'yaml'

module Kuby
  module Kubernetes
    class CLI < CLIBase
      attr_reader :kubeconfig_path, :executable

      def initialize(kubeconfig_path, executable = nil)
        @kubeconfig_path = kubeconfig_path
        @executable = executable || `which kubectl`.strip
      end

      def apply(object)
        cmd = [executable, 'apply', '-f', '-']

        pipeline_w(env, cmd) do |stdin, _wait_threads|
          stdin.puts(YAML.dump(object.to_resource.serialize))
        end
      end

      private

      def env
        @env ||= {
          'KUBECONFIG' => kubeconfig_path
        }
      end
    end
  end
end
