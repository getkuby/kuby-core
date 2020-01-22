module Kuby
  module Docker
    class Phase
      attr_reader :app

      def initialize(app)
        @app = app
      end
    end
  end
end
