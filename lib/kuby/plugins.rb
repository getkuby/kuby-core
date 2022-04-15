# typed: strict
module Kuby
  module Plugins
    autoload :NginxIngress, 'kuby/plugins/nginx_ingress'
    autoload :RailsApp,     'kuby/plugins/rails_app'
    autoload :System,       'kuby/plugins/system'
  end
end
