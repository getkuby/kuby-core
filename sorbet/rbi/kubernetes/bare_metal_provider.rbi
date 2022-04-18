# typed: strict

module Kuby
  module Kubernetes
    class BareMetalProvider < Provider
      class Config
        sig { returns(String) }
        def kubeconfig; end

        sig { returns(String) }
        def storage_class; end

        # For some reason, sorbet doesn't see the `extend ValueFields`
        # call in the Config class. Might be because ValueFields
        # hasn't been annotated?
        sig { params(fields: Symbol).void }
        def self.value_fields(*fields); end
      end

      # These methods actually exist on the Config class, but
      # sorbet doesn't know that because they're instance_evaled.
      # Added these stub to make sorbet shut up.
      sig { params(path: T.nilable(String)).returns(String) }
      def kubeconfig(path = nil); end

      sig { params(class_name: T.nilable(String)).returns(String) }
      def storage_class(class_name = nil); end
    end
  end
end
