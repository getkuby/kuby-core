module Kuby
  module Docker
    class TimestampTag
      RE = /\A20[\d]{2}(?:0[1-9]|10|11|12)(?:0[1-9]|1[1-9]|2[1-9]|3[01])\z/.freeze
      FORMAT = '%Y%m%d%H%M%S'.freeze

      def self.try_parse(str)
        if str =~ RE
          new(Time.strptime(str, FORMAT))
        end
      end

      attr_reader :time

      def initialize(time)
        @time = time
      end

      def to_s
        time.strftime(FORMAT)
      end

      def <=>(other)
        time <=> other.time
      end

      def hash
        time.hash
      end

      def eql?(other)
        time == other.time
      end
    end
  end
end
