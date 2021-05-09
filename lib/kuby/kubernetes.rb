# typed: strict
require 'kuby/kubernetes/errors'

module Kuby
  module Kubernetes
    autoload :BareMetalProvider,     'kuby/kubernetes/bare_metal_provider'
    autoload :Deployer,              'kuby/kubernetes/deployer'
    autoload :DeployTask,            'kuby/kubernetes/deploy_task'
    autoload :DockerConfig,          'kuby/kubernetes/docker_config'
    autoload :DockerDesktopProvider, 'kuby/kubernetes/docker_desktop_provider'
    autoload :Manifest,              'kuby/kubernetes/manifest'
    autoload :Plugins,               'kuby/kubernetes/plugins'
    autoload :Provider,              'kuby/kubernetes/provider'
    autoload :RegistrySecret,        'kuby/kubernetes/registry_secret'
    autoload :Spec,                  'kuby/kubernetes/spec'
  end
end
