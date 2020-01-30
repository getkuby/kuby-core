require 'colorized_string'
require 'open3'
require 'thread'

module Kuby
  class CLIBase
    def last_status
      Thread.current[status_key]
    end

    private

    def open3_w(env, cmd, opts = {}, &block)
      cmd_s = cmd.join(' ')

      Open3.pipeline_w([env, cmd_s], opts) do |stdin, wait_threads|
        yield(stdin, wait_threads).tap do
          stdin.close
          self.last_status = wait_threads.last.value
        end
      end
    end

    def execc(cmd)
      cmd_s = cmd.join(' ')
      exec(cmd_s)
    end

    def systemm(cmd)
      cmd_s = cmd.join(' ')
      system(cmd_s).tap do
        self.last_status = $?
      end
    end

    def backticks(cmd)
      cmd_s = cmd.join(' ')
      `#{cmd_s}`.tap do
        self.last_status = $?
      end
    end

    def last_status=(status)
      Thread.current[status_key] = status
    end

    def status_key
      raise NotImplementedError, "#{__method__} must be defined in derived classes"
    end
  end
end
