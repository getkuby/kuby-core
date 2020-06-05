require 'kuby/kubernetes/errors'

module Kuby
  module Kubernetes
    autoload :MinikubeProvider, 'kuby/kubernetes/minikube_provider'
    autoload :Deployer,         'kuby/kubernetes/deployer'
    autoload :DockerConfig,     'kuby/kubernetes/docker_config'
    autoload :Manifest,         'kuby/kubernetes/manifest'
    autoload :Monitors,         'kuby/kubernetes/monitors'
    autoload :Plugin,           'kuby/kubernetes/plugin'
    autoload :Plugins,          'kuby/kubernetes/plugins'
    autoload :Provider,         'kuby/kubernetes/provider'
    autoload :RegistrySecret,   'kuby/kubernetes/registry_secret'
    autoload :Spec,             'kuby/kubernetes/spec'
  end
end
