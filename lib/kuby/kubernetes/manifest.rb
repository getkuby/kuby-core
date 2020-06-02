require 'set'

module Kuby
  module Kubernetes
    class Manifest
      include Enumerable

      def initialize(resources)
        @resources = resources

        ensure_all_resources_unique!
      end

      def each(&block)
        @resources.each(&block)
      end

      def find(kind, name)
        @resources.find do |resource|
          matches?(resource, kind, name)
        end
      end

      def delete(kind, name)
        idx = @resources.index do |resource|
          matches?(resource, kind, name)
        end

        resources.delete(idx) if idx
      end

      def <<(resource)
        @resources << resource
      end

      private

      def matches?(resource, kind, name)
        resource.kind_sym == kind && resource.metadata.name == name
      end

      def ensure_all_resources_unique!
        seen = Set.new

        @resources.each do |resource|
          key = "#{resource.kind_sym}-#{resource.metadata.name}"

          if seen.include?(key)
            raise DuplicateResourceError, "found more than one #{resource.kind.downcase} "\
              "resource named '#{resource.metadata.name}'"
          end
        end
      end
    end
  end
end
