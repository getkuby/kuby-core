# typed: false

module Kuby
  module Docker
    class Image
      extend T::Sig

      sig { returns(String) }
      attr_reader :image_url

      sig { returns(T.nilable(String)) }
      attr_reader :registry_index_url

      sig { returns(Credentials) }
      attr_reader :credentials

      sig { returns(VersionStrategy) }
      attr_reader :version_strategy

      sig {
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Dockerfile)),
          image_url: String,
          credentials: Credentials,
          version_strategy: Symbol,
          registry_index_url: T.nilable(String)
        ).void
      }
      def initialize(dockerfile, image_url, credentials, version_strategy, registry_index_url = nil)
        @dockerfile = T.let(dockerfile, T.any(Dockerfile, T.proc.returns(Dockerfile)))
        @image_url = T.let(image_url, String)
        @registry_index_url = T.let(registry_index_url, T.nilable(String))
        @credentials = T.let(credentials, Credentials)
        @version_strategy = T.let(Kuby::Docker.version_strategies.fetch(version_strategy).new(self), VersionStrategy)

        @image_host = T.let(@image_host, T.nilable(String))
        @image_hostname = T.let(@image_hostname, T.nilable(String))
        @registry_index_host = T.let(@registry_index_host, T.nilable(String))
        @registry_index_hostname = T.let(@registry_index_hostname, T.nilable(String))
        @registry_index_uri = T.let(@registry_index_uri, T.nilable(DockerURI))
        @image_repo = T.let(@image_repo, T.nilable(String))
        @full_image_uri = T.let(@full_image_uri, T.nilable(DockerURI))
      end

      sig { returns(String) }
      def identifier
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      sig { returns(ImageVersion) }
      def new_version
        version_strategy.new_version
      end

      sig { returns(ImageVersion) }
      def current_version
        version_strategy.current_version
      end

      sig { params(current_tag: T.nilable(String)).returns(ImageVersion) }
      def previous_version(current_tag = nil)
        version_strategy.previous_version
      end

      sig { returns(Dockerfile) }
      def dockerfile
        if @dockerfile.respond_to?(:call)
          T.cast(@dockerfile, T.proc.returns(Dockerfile)).call
        else
          T.cast(@dockerfile, Dockerfile)
        end
      end

      sig { returns(String) }
      def image_host
        @image_host ||= "#{image_uri.host}:#{image_uri.port}"
      end

      sig { returns(String) }
      def registry_index_host
        @registry_index_host ||= "#{registry_index_uri.host}:#{registry_index_uri.port}"
      end

      sig { returns(String) }
      def registry_index_hostname
        @registry_index_hostname ||= registry_index_uri.host
      end

      sig { returns(String) }
      def image_hostname
        @image_hostname ||= image_uri.host
      end

      sig { returns(String) }
      def image_repo
        @image_repo ||= image_uri.path
      end

      sig { returns(DockerURI) }
      def image_uri
        @full_image_uri ||= DockerURI.parse_uri(image_url)
      end

      sig { returns(DockerURI) }
      def registry_index_uri
        @registry_index_uri ||= DockerURI.parse_index_uri(registry_index_url || image_url)
      end
    end
  end
end
