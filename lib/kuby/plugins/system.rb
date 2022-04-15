# typed: true

require 'kube-dsl'

module Kuby
  module Plugins
    class System < ::Kuby::Plugin
      # Kubernetes maintains backwards compatibility for the three most recent
      # minor versions. In other words, everything that works in v1.23 also works
      # in v1.22 and v1.21. Kuby tries to do the same. As of the time of this
      # writing, the most recent k8s release is v1.23, so Kuby supports v1.21 and up.
      depends_on :kubernetes, '~> 1.21'
      depends_on :kubectl, '~> 1.21'
    end
  end
end
