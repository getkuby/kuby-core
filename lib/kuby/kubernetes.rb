module Kuby
  module Kubernetes
    autoload :ConfigMap,      'kuby/kubernetes/config_map'
    autoload :Deployment,     'kuby/kubernetes/deployment'
    autoload :Ingress,        'kuby/kubernetes/ingress'
    autoload :KeyValuePairs,  'kuby/kubernetes/key_value_pairs'
    autoload :Labels,         'kuby/kubernetes/labels'
    autoload :Secrets,        'kuby/kubernetes/secrets'
    autoload :Selector,       'kuby/kubernetes/selector'
    autoload :Service,        'kuby/kubernetes/service'
    autoload :ServiceAccount, 'kuby/kubernetes/service_account'
    autoload :ServicePort,    'kuby/kubernetes/service_port'
    autoload :Spec,           'kuby/kubernetes/spec'
  end
end
