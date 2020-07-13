require 'krane'
require 'ext/krane/kubernetes_resource'
require 'kubectl-rb'

module Kuby
  module Kubernetes
    class DeployTask
      attr_reader :deploy_task

      def initialize(**kwargs)
        @deploy_task ||= ::Krane::DeployTask.new(**kwargs)
      end

      def run!(**kwargs)
        new_path = "#{File.dirname(KubectlRb.executable)}:#{ENV['PATH']}"

        with_env('PATH' => new_path) do
          deploy_task.run!(**kwargs)
        end
      end

      private

      def with_env(new_env)
        old_env = ENV.to_h
        ENV.replace(old_env.merge(new_env))
        yield
      ensure
        ENV.replace(old_env)
      end
    end
  end
end
