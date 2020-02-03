require 'kuby/docker/errors'

module Kuby
  module Docker
    autoload :AssetsPhase,    'kuby/docker/assets_phase'
    autoload :BundlerPhase,   'kuby/docker/bundler_phase'
    autoload :CLI,            'kuby/docker/cli'
    autoload :CopyPhase,      'kuby/docker/copy_phase'
    autoload :Credentials,    'kuby/docker/credentials'
    autoload :Dockerfile,     'kuby/docker/dockerfile'
    autoload :LayerStack,     'kuby/docker/layer_stack'
    autoload :Metadata,       'kuby/docker/metadata'
    autoload :PackagePhase,   'kuby/docker/package_phase'
    autoload :Phase,          'kuby/docker/phase'
    autoload :SetupPhase,     'kuby/docker/setup_phase'
    autoload :Spec,           'kuby/docker/spec'
    autoload :WebserverPhase, 'kuby/docker/webserver_phase'
    autoload :YarnPhase,      'kuby/docker/yarn_phase'
  end
end
