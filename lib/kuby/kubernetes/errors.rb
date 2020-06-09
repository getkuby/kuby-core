module Kuby
  module Kubernetes
    class MissingDeploymentError < StandardError; end
    class MissingProviderError < StandardError; end
    class MissingPluginError < StandardError; end

    class MissingResourceError < StandardError; end
    class DuplicateResourceError < StandardError; end
  end
end
