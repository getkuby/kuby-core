module Kuby
  module Kubernetes
    class Plugin
      attr_reader :definition

      def initialize(definition)
        @definition = definition
        after_initialize
      end

      def configure(&block)
        # do nothing by default
      end

      private

      def after_initialize
        # override this in derived classes
      end
    end
  end
end
