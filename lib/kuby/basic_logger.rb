require 'logger'
require 'colorized_string'

module Kuby
  class BasicLogger < Logger
    def initialize(*args)
      super

      self.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end
    end

    def info(msg, *args)
      super(ColorizedString[msg].yellow, *args)
    end

    def fatal(msg, *args)
      super(ColorizedString[msg].red, *args)
    end
  end
end
