module Kuby
  module Kubernetes
    module Plugins
      autoload :NginxIngress, 'kuby/kubernetes/plugins/nginx_ingress'
      autoload :RailsApp,     'kuby/kubernetes/plugins/rails_app'
    end
  end
end
