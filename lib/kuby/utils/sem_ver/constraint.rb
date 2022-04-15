module Kuby
  module Utils
    module SemVer
      class Constraint
        OPERATOR_MAP = {
          '='  => :eq,
          '>'  => :gt,
          '>=' => :gteq,
          '<'  => :lt,
          '<=' => :lteq,
          '~>' => :waka
        }

        OPERATOR_MAP.freeze

        OPERATOR_INVERSE = OPERATOR_MAP.invert.freeze

        attr_reader :operator, :version

        def self.parse(str)
          op, ver = str.split(' ')
          new(OPERATOR_MAP.fetch(op), Version.parse(ver, default: nil))
        end

        def initialize(operator, version)
          @operator = operator
          @version = version
        end

        def to_s
          @str ||= "#{OPERATOR_INVERSE[operator]} #{version}"
        end

        def satisfied_by?(other_version)
          case operator
            when :waka
              arr = version.to_a
              other_arr = other_version.to_a

              arr.each_with_index do |digit, idx|
                break unless digit

                next_digit = arr[idx + 1]

                if next_digit
                  return false if other_arr[idx] != digit
                else
                  return false if other_arr[idx] < digit
                end
              end

              true
            when :eq
              other_version == version
            when :gt
              other_version > version
            when :gteq
              other_version >= version
            when :lt
              other_version < version
            when :lteq
              other_version <= version
          end
        end
      end
    end
  end
end
