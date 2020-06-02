require 'kuby/docker/errors'

module Kuby
  module Docker
    autoload :Alpine,         'kuby/docker/alpine'
    autoload :AssetsPhase,    'kuby/docker/assets_phase'
    autoload :BundlerPhase,   'kuby/docker/bundler_phase'
    autoload :CLI,            'kuby/docker/cli'
    autoload :CopyPhase,      'kuby/docker/copy_phase'
    autoload :Credentials,    'kuby/docker/credentials'
    autoload :Debian,         'kuby/docker/debian'
    autoload :Dockerfile,     'kuby/docker/dockerfile'
    autoload :LayerStack,     'kuby/docker/layer_stack'
    autoload :LocalTags,      'kuby/docker/local_tags'
    autoload :Metadata,       'kuby/docker/metadata'
    autoload :Packages,       'kuby/docker/packages'
    autoload :PackagePhase,   'kuby/docker/package_phase'
    autoload :Phase,          'kuby/docker/phase'
    autoload :RemoteTags,     'kuby/docker/remote_tags'
    autoload :SetupPhase,     'kuby/docker/setup_phase'
    autoload :Spec,           'kuby/docker/spec'
    autoload :Tags,           'kuby/docker/tags'
    autoload :TimestampTag,   'kuby/docker/timestamp_tag'
    autoload :WebserverPhase, 'kuby/docker/webserver_phase'
    autoload :YarnPhase,      'kuby/docker/yarn_phase'
  end
end
