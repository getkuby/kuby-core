require 'logger'

module Kuby
  class BasicLogger < Logger
    def initialize(*args)
      super

      self.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end
    end
  end
end
