module Kuby
  module Kubernetes
    class Selector < KeyValuePairs
      def serialize
        { matchLabels: super }
      end
    end
  end
end
