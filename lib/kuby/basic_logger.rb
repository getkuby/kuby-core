# typed: strict

require 'logger'
require 'colorized_string'

module Kuby
  class BasicLogger < Logger
    # extend T::Sig

    # T::Sig::WithoutRuntime.sig {
    #   override.params(
    #     logdev: T.any(String, IO, StringIO, NilClass),
    #     shift_age: Integer,
    #     shift_size: Integer,
    #     level: Integer,
    #     progname: T.nilable(String),
    #     formatter: T.nilable(FormatterProcType),
    #     datetime_format: T.nilable(String),
    #     shift_period_suffix: T.nilable(String)
    #   ).void
    # }
    def initialize(
        logdev, shift_age = 0, shift_size = 1048576, level: DEBUG,
        progname: nil, formatter: nil, datetime_format: nil,
        shift_period_suffix: '%Y%m%d')
      # @logdev = T.let(@logdev, T.nilable(Logger::LogDevice))

      super

      self.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end
    end

    # T::Sig::WithoutRuntime.sig {
    #   override.params(
    #     progname_or_msg: T.untyped,
    #     block: T.nilable(T.proc.returns(T.untyped))
    #   ).void
    # }
    def info(progname_or_msg = nil, &block)
      if block
        super(progname_or_msg) { ColorizedString[block.call].yellow }
      else
        super(ColorizedString[progname_or_msg].yellow)
      end
    end

    # T::Sig::WithoutRuntime.sig {
    #   override.params(
    #     progname_or_msg: T.untyped,
    #     block: T.nilable(T.proc.returns(T.untyped))
    #   ).void
    # }
    def fatal(progname_or_msg = nil, &block)
      if block
        super(progname_or_msg) { ColorizedString[block.call].red }
      else
        super(ColorizedString[progname_or_msg].red)
      end
    end

    # adhere to the "CLI" interface
    # T::Sig::WithoutRuntime.sig {
    #   params(
    #     out: T.any(IO, StringIO),
    #     err: T.any(IO, StringIO),
    #     block: T.proc.void
    #   ).void
    # }
    def with_pipes(out = STDOUT, err = STDERR, &block)
      previous_logdev = @logdev&.dev || STDERR
      reopen(err)
      yield
    ensure
      reopen(previous_logdev)
    end

    # T::Sig::WithoutRuntime.sig { returns(T.nilable(Process::Status)) }
    def last_status
      nil
    end
  end
end
