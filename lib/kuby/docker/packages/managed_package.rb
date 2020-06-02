module Kuby
  module Docker
    module Packages
      class ManagedPackage
        attr_reader :name, :names_per_distro

        def initialize(name, names_per_distro)
          @name = name
          @names_per_distro = names_per_distro
        end

        def package_name_for(distro)
          names_per_distro.fetch(distro) do
            raise UnsupportedDistroError, "Couldn't install #{name} "\
              "because #{distro} is an unsupported distro"
          end
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
