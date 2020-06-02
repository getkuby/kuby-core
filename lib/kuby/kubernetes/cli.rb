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

      def run_cmd(cmd)
        cmd = [executable, '--kubeconfig', kubeconfig_path, *Array(cmd)]
        execc(cmd)
      end

      def exec_cmd(container_cmd, namespace, pod, tty = true)
        cmd = [executable, '--kubeconfig', kubeconfig_path, '-n', namespace, 'exec']
        cmd += ['-it'] if tty
        cmd += [pod, '--', *Array(container_cmd)]
        execc(cmd)
      end

      def apply(res, dry_run: false)
        cmd = [executable, '--kubeconfig', kubeconfig_path, 'apply', '--validate']
        cmd << '--dry-run' if dry_run
        cmd += ['-f', '-']

        open3_w(env, cmd) do |stdin, _wait_thread|
          stdin.puts(res.to_resource.to_yaml)
        end

        unless last_status.success?
          err = InvalidResourceError.new("Could not apply #{res.kind_sym.to_s.humanize.downcase} "\
            "'#{res.metadata.name}': kubectl exited with status code #{last_status.exitstatus}"
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

      def get_object(type, namespace, name = nil, match_labels = {})
        cmd = [executable, '--kubeconfig', kubeconfig_path, '-n', namespace]
        cmd += ['get', type, name]

        unless match_labels.empty?
          cmd += ['--selector', match_labels.map { |key, value| "#{key}=#{value}" }.join(',')]
        end

        cmd += ['-o', 'json']

        result = backticks(cmd)

        unless last_status.success?
          raise GetResourceError, "couldn't get resources of type '#{type}' "\
            "in namespace #{namespace}: kubectl exited with status code #{last_status.exitstatus}"
        end

        JSON.parse(result)
      end

      def get_objects(type, namespace, match_labels = {})
        cmd = [executable, '--kubeconfig', kubeconfig_path, '-n', namespace]
        cmd += ['get', type]

        unless match_labels.empty?
          cmd += ['--selector', match_labels.map { |key, value| "#{key}=#{value}" }.join(',')]
        end

        cmd += ['-o', 'json']

        result = backticks(cmd)

        unless last_status.success?
          raise GetResourceError, "couldn't get resources of type '#{type}' "\
            "in namespace #{namespace}: kubectl exited with status code #{last_status.exitstatus}"
        end

        JSON.parse(result)['items']
      end

      def annotate(type, namespace, name, annotations, overwrite: true)
        cmd = [
          executable,
          '--kubeconfig', kubeconfig_path,
          '-n', namespace,
          'annotate'
        ]

        cmd << '--overwrite' if overwrite
        cmd += [type, name]

        annotations.each do |key, value|
          cmd << "'#{key}'='#{value}'"
        end

        systemm(cmd)

        unless last_status.success?
          raise KubernetesCLIError, "could not annotate resource '#{name}': kubectl "\
            "exited with status code #{last_status.exitstatus}"
        end
      end

      def logtail(namespace, selector, follow: true)
        cmd = [executable, '--kubeconfig', kubeconfig_path, '-n', namespace, 'logs']
        cmd << '-f' if follow
        cmd << '--selector'
        cmd << selector.map { |k, v| "#{k}=#{v}" }.join(',')
        execc(cmd)
      end

      def current_context
        cmd = [executable, '--kubeconfig', kubeconfig_path, 'config', 'current-context']
        backticks(cmd).strip
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
