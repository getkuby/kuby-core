module Kuby
  module Utils
    module SemVer
      class ConstraintSet
        attr_reader :constraints

        def self.parse(*arr)
          new(arr.map { |c| Constraint.parse(c) })
        end

        def initialize(constraints)
          @constraints = constraints
        end

        def satisfied_by?(version)
          constraints.all? { |c| c.satisfied_by?(version) }
        end

        def to_s
          @str ||= constraints.map(&:to_s).join(', ')
        end
      end
    end
  end
end
