require 'colorized_string'
require 'json'
require 'open3'

module Kuby
  module Docker
    class CLI
      attr_reader :executable

      def initialize(executable = nil)
        @executable = executable || `which docker`.strip
      end

      def build(dockerfile:, image_url:, tags:)
        cmd = [
          executable, 'build',
          *tags.flat_map { |tag| ['-t', "#{image_url}:#{tag}"] },
          '-f-', '.'
        ]

        pipeline_w(cmd) do |stdin, _wait_threads|
          stdin.puts(dockerfile.to_s)
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
      end

      private

      def pipeline_w(cmd, opts = {}, &block)
        cmd_s = cmd.join(' ')
        print_cmd(cmd_s)
        Open3.pipeline_w(cmd_s, opts, &block)
      end

      def execc(cmd)
        cmd_s = cmd.join(' ')
        print_cmd(cmd_s)
        exec(cmd_s)
      end

      def systemm(cmd)
        cmd_s = cmd.join(' ')
        print_cmd(cmd_s)
        system(cmd_s)
      end

      def backticks(cmd)
        cmd_s = cmd.join(' ')
        print_cmd(cmd_s)
        `#{cmd_s}`
      end

      def print_cmd(cmd)
        puts ColorizedString["Executing #{cmd}"].yellow
      end
    end
  end
end
