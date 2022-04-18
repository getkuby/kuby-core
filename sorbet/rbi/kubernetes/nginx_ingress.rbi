# typed: true

module Kuby
  module Plugins
    class NginxIngress
      class Config
        extend KubeDSL::ValueFields::ClassMethods
        include KubeDSL::ValueFields::InstanceMethods
      end
    end
  end
end
