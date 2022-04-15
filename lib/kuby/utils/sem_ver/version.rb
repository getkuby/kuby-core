module Kuby
  module Utils
    module SemVer
      class Version
        include Comparable

        attr_reader :major, :minor, :patch

        def self.parse(str, default: 0)
          major, minor, patch = str.split('.')

          new(
            major ? major.to_i : default,
            minor ? minor.to_i : default,
            patch ? patch.to_i : default
          )
        end

        def initialize(major, minor, patch)
          @major = major
          @minor = minor
          @patch = patch
        end

        def to_s
          @str ||= [major, minor, patch].compact.join('.')
        end

        def to_a
          @arr ||= [major, minor, patch]
        end

        def <=>(other)
          other_arr = other.to_a

          to_a.each_with_index do |digit, idx|
            other_digit = other_arr[idx] || 0

            if digit != other_digit
              return digit <=> other_digit
            end
          end

          0
        end
      end
    end
  end
end
