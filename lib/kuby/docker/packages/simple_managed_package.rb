module Kuby
  module Docker
    module Packages
      class SimpleManagedPackage
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def package_name_for(distro)
          name
        end

        def with_version(*)
          self
        end

        def managed?
          true
        end
      end
    end
  end
end
