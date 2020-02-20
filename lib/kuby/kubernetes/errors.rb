module Kuby
  module Kubernetes
    class InvalidResourceError < StandardError
      attr_accessor :resource
    end

    class InvalidResourceUriError < StandardError
      attr_accessor :resource_uri
    end

    class GetResourceError < StandardError; end

    class MissingDeploymentError < StandardError; end

    class MissingProviderError < StandardError; end
    class MissingPluginError < StandardError; end
  end
end
