# typed: strict

module Kuby
  module Kubernetes
    class BareMetalProvider < Provider
      class Config
        sig { returns(String) }
        def kubeconfig; end

        # For some reason, sorbet doesn't see the `extend ValueFields`
        # call in the Config class. Might be because ValueFields
        # hasn't been annotated?
        sig { params(fields: Symbol).void }
        def self.value_fields(*fields); end
      end

      # This method actually exists on the Config class, but
      # sorbet doesn't know that because it's instance_evaled.
      # Added this stub to make sorbet shut up.
      sig { params(path: T.nilable(String)).returns(String) }
      def kubeconfig(path = nil); end
    end
  end
end
