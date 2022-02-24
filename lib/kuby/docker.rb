# typed: ignore

require 'kuby/docker/errors'

module Kuby
  module Docker
    LATEST_TAG = T.let('latest'.freeze, String)

    autoload :Alpine,            'kuby/docker/alpine'
    autoload :AppImage,          'kuby/docker/app_image'
    autoload :AppPhase,          'kuby/docker/app_phase'
    autoload :AssetsPhase,       'kuby/docker/assets_phase'
    autoload :BundlerPhase,      'kuby/docker/bundler_phase'
    autoload :CLI,               'kuby/docker/cli'
    autoload :CopyPhase,         'kuby/docker/copy_phase'
    autoload :Credentials,       'kuby/docker/credentials'
    autoload :Debian,            'kuby/docker/debian'
    autoload :Distro,            'kuby/docker/distro'
    autoload :Dockerfile,        'kuby/docker/dockerfile'
    autoload :DockerURI,         'kuby/docker/docker_uri'
    autoload :Image,             'kuby/docker/image'
    autoload :ImageVersion,      'kuby/docker/image_version'
    autoload :InlineLayer,       'kuby/docker/inline_layer'
    autoload :Layer,             'kuby/docker/layer'
    autoload :LayerStack,        'kuby/docker/layer_stack'
    autoload :LocalTags,         'kuby/docker/local_tags'
    autoload :Packages,          'kuby/docker/packages'
    autoload :PackagePhase,      'kuby/docker/package_phase'
    autoload :RemoteTags,        'kuby/docker/remote_tags'
    autoload :SetupPhase,        'kuby/docker/setup_phase'
    autoload :Spec,              'kuby/docker/spec'
    autoload :TimestampStrategy, 'kuby/docker/timestamp_strategy'
    autoload :TimestampTag,      'kuby/docker/timestamp_tag'
    autoload :VersionStrategy,   'kuby/docker/version_strategy'
    autoload :WebserverPhase,    'kuby/docker/webserver_phase'
    autoload :YarnPhase,         'kuby/docker/yarn_phase'


    @@version_strategies = T.let({}, T::Hash[Symbol, T.class_of(VersionStrategy)])

    class << self
      extend T::Sig

      sig { params(strategy_name: Symbol, strategy_klass: T.class_of(VersionStrategy)).void }
      def register_version_strategy(strategy_name, strategy_klass)
        version_strategies[strategy_name] = strategy_klass
      end

      sig { returns(T::Hash[Symbol, T.class_of(VersionStrategy)]) }
      def version_strategies
        @version_strategies ||= T.let({}, T.nilable(T::Hash[Symbol, T.class_of(VersionStrategy)]))
        T.must(@version_strategies)
      end
    end
  end
end

Kuby::Docker.register_version_strategy(:timestamps, Kuby::Docker::TimestampStrategy)
