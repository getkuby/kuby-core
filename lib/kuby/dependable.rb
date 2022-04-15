module Kuby
  class Dependable
    attr_reader :name, :version_or_callable

    def initialize(name, version_or_callable)
      @name = name
      @version_or_callable = version_or_callable
    end

    def version
      @version ||= Kuby::Utils::SemVer.parse_version(
        if version_or_callable.respond_to?(:call)
          version_or_callable.call
        else
          version_or_callable
        end
      )
    end
  end
end
