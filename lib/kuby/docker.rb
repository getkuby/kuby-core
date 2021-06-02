# typed: strict

require 'kuby/docker/errors'

module Kuby
  module Docker
    LATEST_TAG = T.let('latest'.freeze, String)

    autoload :Alpine,           'kuby/docker/alpine'
    autoload :AppImage,         'kuby/docker/app_image'
    autoload :AssetsPhase,      'kuby/docker/assets_phase'
    autoload :BundlerPhase,     'kuby/docker/bundler_phase'
    autoload :CLI,              'kuby/docker/cli'
    autoload :CopyPhase,        'kuby/docker/copy_phase'
    autoload :Credentials,      'kuby/docker/credentials'
    autoload :Debian,           'kuby/docker/debian'
    autoload :Distro,           'kuby/docker/distro'
    autoload :Dockerfile,       'kuby/docker/dockerfile'
    autoload :DockerURI,        'kuby/docker/docker_uri'
    autoload :Image,            'kuby/docker/image'
    autoload :InlineLayer,      'kuby/docker/inline_layer'
    autoload :Layer,            'kuby/docker/layer'
    autoload :LayerStack,       'kuby/docker/layer_stack'
    autoload :LocalTags,        'kuby/docker/local_tags'
    autoload :Packages,         'kuby/docker/packages'
    autoload :PackagePhase,     'kuby/docker/package_phase'
    autoload :RemoteTags,       'kuby/docker/remote_tags'
    autoload :SetupPhase,       'kuby/docker/setup_phase'
    autoload :Spec,             'kuby/docker/spec'
    autoload :TimestampedImage, 'kuby/docker/timestamped_image'
    autoload :TimestampTag,     'kuby/docker/timestamp_tag'
    autoload :WebserverPhase,   'kuby/docker/webserver_phase'
    autoload :YarnPhase,        'kuby/docker/yarn_phase'
  end
end
