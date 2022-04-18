# typed: strict

require 'open3'
require 'thread'

module Kuby
  class CLIBase
    extend T::Sig

    BeforeCallback = T.type_alias { T.proc.params(cmd: T::Array[String]).void }
    AfterCallback = T.type_alias do
      T.proc.params(cmd: T::Array[String], last_status: T.nilable(Process::Status)).void
    end

    T::Sig::WithoutRuntime.sig { returns(T.nilable(Process::Status)) }
    def last_status
      Thread.current[status_key]
    end

    T::Sig::WithoutRuntime.sig { params(block: BeforeCallback).void }
    def before_execute(&block)
      @before_execute = T.let(@before_execute, T.nilable(T::Array[BeforeCallback]))
      @before_execute ||= []
      @before_execute << block
    end

    T::Sig::WithoutRuntime.sig { params(block: AfterCallback).void }
    def after_execute(&block)
      @after_execute = T.let(@after_execute, T.nilable(T::Array[AfterCallback]))
      @after_execute ||= []
      @after_execute << block
    end

    T::Sig::WithoutRuntime.sig {
      params(
        out: T.any(IO, StringIO),
        err: T.any(IO, StringIO),
        block: T.proc.void
      ).void
    }
    def with_pipes(out = STDOUT, err = STDERR, &block)
      previous_stdout = self.stdout
      previous_stderr = self.stderr
      self.stdout = out
      self.stderr = err
      yield
    ensure
      self.stdout = previous_stdout
      self.stderr = previous_stderr
    end

    T::Sig::WithoutRuntime.sig { returns(T.nilable(T.any(IO, StringIO))) }
    def stdout
      Thread.current[stdout_key] || STDOUT
    end

    T::Sig::WithoutRuntime.sig { params(new_stdout: T.nilable(T.any(IO, StringIO))).void }
    def stdout=(new_stdout)
      Thread.current[stdout_key] = new_stdout
    end

    T::Sig::WithoutRuntime.sig { returns(T.nilable(T.any(IO, StringIO))) }
    def stderr
      Thread.current[stderr_key] || STDERR
    end

    T::Sig::WithoutRuntime.sig { params(new_stderr: T.nilable(T.any(IO, StringIO))).void }
    def stderr=(new_stderr)
      Thread.current[stderr_key] = new_stderr
    end

    private

    T::Sig::WithoutRuntime.sig {
      params(
        cmd: T::Array[String],
        block: T.proc.params(stdin: IO).void
      ).void
    }
    def open3_w(cmd, &block)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')

      Open3.popen3(cmd_s) do |p_stdin, p_stdout, p_stderr, wait_thread|
        Thread.new(stdout) do |t_stdout|
          begin
            p_stdout.each { |line| t_stdout.puts(line) }
          rescue IOError
          end
        end

        Thread.new(stderr) do |t_stderr|
          begin
            p_stderr.each { |line| t_stderr.puts(line) }
          rescue IOError
          end
        end

        yield(p_stdin)

        p_stdin.close
        self.last_status = T.cast(wait_thread.value, Process::Status)
        run_after_callbacks(cmd)
        wait_thread.join
      end
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).void }
    def execc(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      exec(cmd_s)
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).void }
    def systemm(cmd)
      if stdout == STDOUT && stderr == STDERR
        systemm_default(cmd)
      else
        systemm_open3(cmd)
      end
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).void }
    def systemm_default(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      system(cmd_s).tap do
        self.last_status = $?
        run_after_callbacks(cmd)
      end
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).void }
    def systemm_open3(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')

      Open3.popen3(cmd_s) do |p_stdin, p_stdout, p_stderr, wait_thread|
        Thread.new(stdout) do |t_stdout|
          begin
            p_stdout.each { |line| t_stdout.puts(line) }
          rescue IOError
          end
        end

        Thread.new(stderr) do |t_stderr|
          begin
            p_stderr.each { |line| t_stderr.puts(line) }
          rescue IOError
          end
        end

        p_stdin.close
        self.last_status = T.cast(wait_thread.value, Process::Status)
        run_after_callbacks(cmd)
        wait_thread.join
      end
    end


    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).returns(String) }
    def backticks(cmd)
      if stdout == STDOUT && stderr == STDERR
        backticks_default(cmd)
      else
        backticks_open3(cmd)
      end
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).returns(String) }
    def backticks_default(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      `#{cmd_s}`.tap do
        self.last_status = $?
        run_after_callbacks(cmd)
      end
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).returns(String) }
    def backticks_open3(cmd)
      run_before_callbacks(cmd)
      cmd_s = cmd.join(' ')
      result = StringIO.new

      Open3.popen3(cmd_s) do |p_stdin, p_stdout, p_stderr, wait_thread|
        Thread.new do
          begin
            p_stdout.each { |line| result.puts(line) }
          rescue IOError
          end
        end

        Thread.new(stderr) do |t_stderr|
          begin
            p_stderr.each { |line| t_stderr.puts(line) }
          rescue IOError
          end
        end

        p_stdin.close
        self.last_status = T.cast(wait_thread.value, Process::Status)
        run_after_callbacks(cmd)
        wait_thread.join
      end

      result.string
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).void }
    def run_before_callbacks(cmd)
      (@before_execute || []).each { |cb| cb.call(cmd) }
    end

    T::Sig::WithoutRuntime.sig { params(cmd: T::Array[String]).void }
    def run_after_callbacks(cmd)
      (@after_execute || []).each { |cb| cb.call(cmd, last_status) }
    end

    T::Sig::WithoutRuntime.sig { params(status: Process::Status).void }
    def last_status=(status)
      Thread.current[status_key] = status
    end

    T::Sig::WithoutRuntime.sig { returns(Symbol) }
    def status_key
      raise NotImplementedError, "#{__method__} must be defined in derived classes"
    end

    T::Sig::WithoutRuntime.sig { returns(Symbol) }
    def stdout_key
      raise NotImplementedError, "#{__method__} must be defined in derived classes"
    end

    T::Sig::WithoutRuntime.sig { returns(Symbol) }
    def stderr_key
      raise NotImplementedError, "#{__method__} must be defined in derived classes"
    end
  end
end
