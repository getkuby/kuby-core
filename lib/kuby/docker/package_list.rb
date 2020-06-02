module Kuby
  module Docker
    class PackageList
      include Enumerable

      attr_reader :packages

      def initialize(package_tuples)
        @packages = []
        package_tuples.each { |pt| add(*pt) }
      end

      def [](name)
        packages.find { |pkg| pkg.name == name }
      end

      def add(name, version = nil)
        packages << Package.new(name, version)
      end

      def delete(name)
        packages.delete_if { |pkg| pkg.name == name }
      end

      def each(&block)
        packages.each(&block)
      end

      def empty?
        packages.empty?
      end
    end
  end
end
