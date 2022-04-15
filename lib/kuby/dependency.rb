module Kuby
  class Dependency
    attr_reader :name, :constraints

    def initialize(name, *constraints)
      @name = name
      @constraints = Kuby::Utils::SemVer.parse_constraints(*constraints)
    end

    def satisfied_by?(dependable)
      constraints.satisfied_by?(dependable.version)
    end
  end
end
