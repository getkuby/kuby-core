require 'open3'
require 'thread'

module Kuby
  class CLIBase
    def last_status
      Thread.current[status_key]
    end

    def before_execute(&block)
      @before_execute ||= []
      @before_execute << block
    end

    def after_execute(&block)
      @after_execute ||= []
      @after_execute << block
    end

    private

    def open3_w(env, cmd, opts = {}, &block)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')

      Open3.pipeline_w([env, cmd_s], opts) do |stdin, wait_threads|
        yield(stdin, wait_threads).tap do
          stdin.close
          self.last_status = wait_threads.last.value
          run_after_callbacks(cmd)
        end
      end
    end

    def execc(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      exec(cmd_s)
    end

    def systemm(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      system(cmd_s).tap do
        self.last_status = $?
        run_after_callbacks(cmd)
      end
    end

    def backticks(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      `#{cmd_s}`.tap do
        self.last_status = $?
        run_after_callbacks(cmd)
      end
    end

    def run_before_callbacks(cmd)
      (@before_execute || []).each { |cb| cb.call(cmd) }
    end

    def run_after_callbacks(cmd)
      (@after_execute || []).each { |cb| cb.call(cmd, last_status) }
    end

    def last_status=(status)
      Thread.current[status_key] = status
    end

    def status_key
      raise NotImplementedError, "#{__method__} must be defined in derived classes"
    end
  end
end
