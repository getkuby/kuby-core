
# typed: strict

module Kuby
  module Docker
    class AppImage < Image
      extend T::Sig

      sig { returns(String) }
      def identifier
        'app'.freeze
      end
    end
  end
end
