require 'kuby/kubernetes/errors'

module Kuby
  module Kubernetes
    autoload :CLI,              'kuby/kubernetes/cli'
    autoload :MinikubeProvider, 'kuby/kubernetes/minikube_provider'
    autoload :Deployer,         'kuby/kubernetes/deployer'
    autoload :DeployTask,       'kuby/kubernetes/deploy_task'
    autoload :DockerConfig,     'kuby/kubernetes/docker_config'
    autoload :Monitors,         'kuby/kubernetes/monitors'
    autoload :Plugin,           'kuby/kubernetes/plugin'
    autoload :Plugins,          'kuby/kubernetes/plugins'
    autoload :Provider,         'kuby/kubernetes/provider'
    autoload :RegistrySecret,   'kuby/kubernetes/registry_secret'
    autoload :Spec,             'kuby/kubernetes/spec'
  end
end
