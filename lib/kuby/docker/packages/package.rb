module Kuby
  module Docker
    module Packages
      class Package
        attr_reader :name, :version

        def initialize(name, version = nil)
          @name = name
          @version = version
        end

        def with_version(ver)
          self.class.new(name, ver)
        end

        def managed?
          false
        end
      end
    end
  end
end
