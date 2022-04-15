module Kuby
  module Utils
    module SemVer
      autoload :Constraint,    'kuby/utils/sem_ver/constraint'
      autoload :ConstraintSet, 'kuby/utils/sem_ver/constraint_set'
      autoload :Version,       'kuby/utils/sem_ver/version'

      def self.parse_version(str)
        Version.parse(str)
      end

      def self.parse_constraints(*strs)
        ConstraintSet.parse(*strs)
      end
    end
  end
end
