module Kuby
  module Kubernetes
    class KubernetesCLIError < StandardError; end

    class InvalidResourceError < KubernetesCLIError
      attr_accessor :resource
    end

    class InvalidResourceUriError < KubernetesCLIError
      attr_accessor :resource_uri
    end

    class GetResourceError < KubernetesCLIError; end

    class MissingDeploymentError < StandardError; end
    class MissingProviderError < StandardError; end
    class MissingPluginError < StandardError; end

    class MissingResourceError < StandardError; end
    class DuplicateResourceError < StandardError; end
  end
end
