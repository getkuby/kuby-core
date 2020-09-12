require 'json'
require 'open3'
require 'shellwords'

module Kuby
  module Docker
    class CLI < CLIBase
      attr_reader :executable

      def initialize(executable = nil)
        @executable = executable || `which docker`.strip
      end

      def config_file
        if File.exist?(default_config_file)
          default_config_file
        end
      end

      def default_config_file
        File.join(Dir.home, '.docker', 'config.json')
      end

      def login(url:, username:, password:)
        cmd = [
          executable, 'login', url, '--username', username, '--password-stdin'
        ]

        open3_w({}, cmd) do |stdin, _wait_threads|
          stdin.puts(password)
        end

        unless last_status.success?
          raise LoginError, 'build failed: docker command exited with '\
            "status code #{last_status.exitstatus}"
        end
      end

      def auths
        return [] unless config_file

        config = JSON.parse(File.read(config_file))
        config.fetch('auths', {}).keys
      end

      def build(dockerfile:, image_url:, tags:, build_args: {})
        cmd = [
          executable, 'build',
          *tags.flat_map { |tag| ['-t', "#{image_url}:#{tag}"] },
          *build_args.flat_map do |arg, val|
            ['--build-arg', Shellwords.shellescape("#{arg}=#{val}")]
          end,
          '-f-', '.'
        ]

        open3_w({}, cmd) do |stdin, _wait_threads|
          stdin.puts(dockerfile.to_s)
        end

        unless last_status.success?
          raise BuildError, 'build failed: docker command exited with '\
            "status code #{last_status.exitstatus}"
        end
      end

      def run(image_url:, tag: 'latest', env: {}, ports: [])
        cmd = [
          executable, 'run',
          *env.flat_map { |k, v| ['-e', "#{k}=#{v}"] },
          *ports.flat_map { |port| ['-p', "#{port}:#{port}"] },
          '--init',
          '--rm',
          "#{image_url}:#{tag}"
        ]

        execc(cmd)
      end

      def images(image_url)
        cmd = [
          executable, 'images', image_url,
          '--format', '"{{json . }}"'
        ]

        backticks(cmd).split("\n").map do |image_data|
          JSON.parse(image_data).each_with_object({}) do |(k, v), ret|
            ret[k.underscore.to_sym] = v
          end
        end
      end

      def push(image_url, tag)
        systemm([
          executable, 'push', "#{image_url}:#{tag}"
        ])

        unless last_status.success?
          raise PushError, 'push failed: docker command exited with '\
            "status code #{last_status.exitstatus}"
        end
      end

      def pull(image_url, tag)
        systemm([
          executable, 'pull', "#{image_url}:#{tag}"
        ])

        unless last_status.success?
          raise PullError, 'pull failed: docker command exited with '\
            "status code #{last_status.exitstatus}"
        end
      end

      def status_key
        :kuby_docker_cli_last_status
      end

      def stdout_key
        :kuby_docker_stdout
      end

      def stderr_key
        :kuby_docker_stderr
      end
    end
  end
end
