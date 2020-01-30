module Kuby
  module Kubernetes
    module Monitors
      autoload :Deployment, 'kuby/kubernetes/monitors/deployment'
      autoload :Generic,    'kuby/kubernetes/monitors/generic'

      MONITOR_MAP = {
        deployment: Deployment
      }

      def self.for(object, *args, **kwargs)
        klass = MONITOR_MAP[object.kind] || Generic
        klass.new(object, *args, **kwargs)
      end
    end
  end
end
