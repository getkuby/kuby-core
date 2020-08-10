module Kuby
  module Docker
    class TimestampTag
      FORMAT = '%Y%m%d%H%M%S'.freeze

      def self.try_parse(str)
        return nil unless str

        new(Time.strptime(str, FORMAT))
      rescue ArgumentError
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
