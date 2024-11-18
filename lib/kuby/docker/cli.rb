# typed: strict

require 'json'
require 'open3'
require 'shellwords'

module Kuby
  module Docker
    class CLI < CLIBase
      extend T::Sig

      T::Sig::WithoutRuntime.sig { returns(String) }
      attr_reader :executable

      T::Sig::WithoutRuntime.sig { params(executable: T.nilable(String)).void }
      def initialize(executable = nil)
        @executable = T.let(executable || Kuby::Utils.which('docker'), String)
      end

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      def config_file
        if File.exist?(default_config_file)
          default_config_file
        end
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def default_config_file
        File.join(Dir.home, '.docker', 'config.json')
      end

      T::Sig::WithoutRuntime.sig { params(url: String, username: String, password: String).void }
      def login(url:, username:, password:)
        cmd = [
          executable, 'login', url, '--username', username, '--password-stdin'
        ]

        open3_w(cmd) do |stdin, _wait_threads|
          stdin.puts(password)
        end

        unless T.must(last_status).success?
          raise LoginError, 'build failed: docker command exited with '\
            "status code #{T.must(last_status).exitstatus}"
        end
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      def auths
        return [] unless config_file

        config = JSON.parse(File.read(T.must(config_file)))
        config.fetch('auths', {}).keys
      end

      T::Sig::WithoutRuntime.sig {
        params(
          image: Image,
          build_args: T::Hash[T.any(Symbol, String), String],
          docker_args: T::Array[String],
          context: T.nilable(String),
          cache_from: T.nilable(String)
        ).void
      }
      def build(image, build_args: {}, docker_args: [], context: nil, cache_from: nil)
        cmd = [
          executable, 'build',
          *image.tags.flat_map { |tag| ['-t', "#{image.image_url}:#{tag}"] },
          *build_args.flat_map do |arg, val|
            ['--build-arg', Shellwords.shellescape("#{arg}=#{val}")]
          end
        ]

        if cache_from
          cmd += ['--cache-from', cache_from]
        end

        cmd += [
          '-f-',
          *docker_args,
          context || '.'
        ]

        open3_w(cmd) do |stdin, _wait_threads|
          stdin.puts(image.dockerfile.to_s)
        end

        unless T.must(last_status).success?
          raise BuildError, 'build failed: docker command exited with '\
            "status code #{T.must(last_status).exitstatus}"
        end
      end

      T::Sig::WithoutRuntime.sig {
        params(
          image_url: String,
          tag: String,
          env: T::Hash[T.any(Symbol, String), String],
          ports: T::Array[T.any(String, Integer)]
        )
        .void
      }
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

      T::Sig::WithoutRuntime.sig { params(container: String, command: String, tty: T::Boolean).returns(String) }
      def exec_capture(container:, command:, tty: true)
        cmd = [executable, 'exec']
        cmd << '-it' if tty
        cmd += [container, command]

        backticks(cmd)
      end

      T::Sig::WithoutRuntime.sig { params(image_url: String, tag: String, format: T.nilable(String)).returns(String) }
      def inspect(image_url:, tag: 'latest', format: nil)
        cmd = [executable, 'inspect']
        cmd += ['--format', "'#{format}'"]
        cmd << "#{image_url}:#{tag}"

        backticks(cmd)
      end

      T::Sig::WithoutRuntime.sig { params(image_url: String, digests: T::Boolean).returns(T::Array[T::Hash[Symbol, String]]) }
      def images(image_url, digests: true)
        cmd = [
          executable, 'images', image_url,
          '--format', '"{{json . }}"'
        ]

        cmd << '--digests' if digests

        backticks(cmd).split("\n").map do |image_data|
          JSON.parse(image_data).each_with_object({}) do |(k, v), ret|
            ret[k.underscore.to_sym] = v
          end
        end
      end

      T::Sig::WithoutRuntime.sig { params(image_url: String, tag: String).void }
      def push(image_url, tag)
        systemm([
          executable, 'push', "#{image_url}:#{tag}"
        ])

        unless T.must(last_status).success?
          raise PushError, 'push failed: docker command exited with '\
            "status code #{T.must(last_status).exitstatus}"
        end
      end

      T::Sig::WithoutRuntime.sig { params(image_url: String, tag: String).void }
      def pull(image_url, tag)
        systemm([
          executable, 'pull', "#{image_url}:#{tag}"
        ])

        unless T.must(last_status).success?
          raise PullError, 'pull failed: docker command exited with '\
            "status code #{T.must(last_status).exitstatus}"
        end
      end

      T::Sig::WithoutRuntime.sig { returns(Symbol) }
      def status_key
        :kuby_docker_cli_last_status
      end

      T::Sig::WithoutRuntime.sig { returns(Symbol) }
      def stdout_key
        :kuby_docker_stdout
      end

      T::Sig::WithoutRuntime.sig { returns(Symbol) }
      def stderr_key
        :kuby_docker_stderr
      end
    end
  end
end
