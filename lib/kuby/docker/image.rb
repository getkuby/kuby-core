# typed: strict

module Kuby
  module Docker
    class Image
      extend T::Sig

      DEFAULT_REGISTRY_METADATA_HOST = T.let('index.docker.io'.freeze, String)
      DEFAULT_REGISTRY_METADATA_PORT = T.let(443, Integer)

      sig { returns(T.nilable(String)) }
      attr_reader :identifier

      sig { returns(String) }
      attr_reader :image_url

      sig { returns(String) }
      attr_reader :registry_metadata_url

      sig { returns(Credentials) }
      attr_reader :credentials

      sig { returns(T.nilable(String)) }
      attr_reader :main_tag

      sig { returns T::Array[String] }
      attr_reader :alias_tags

      sig {
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Dockerfile)),
          image_url: String,
          credentials: Credentials,
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      }
      def initialize(dockerfile, image_url, credentials, registry_metadata_url = nil, main_tag = nil, alias_tags = [])
        @dockerfile = T.let(dockerfile, T.any(Dockerfile, T.proc.returns(Dockerfile)))
        @image_url = T.let(image_url, String)
        @registry_metadata_url = T.let(registry_metadata_url, String)
        @credentials = T.let(credentials, Credentials)
        @main_tag = T.let(main_tag, T.nilable(String))
        @alias_tags = T.let(alias_tags, T::Array[String])
        @identifier = T.let(@identifier, T.nilable(String))

        @image_host = T.let(@image_host, T.nilable(String))
        @image_hostname = T.let(@image_hostname, T.nilable(String))
        @image_repo = T.let(@image_repo, T.nilable(String))
        @full_image_uri = T.let(@full_image_uri, T.nilable(DockerURI))
        @docker_cli = T.let(@docker_cli, T.nilable(Docker::CLI))
      end

      sig { returns(Image) }
      def new_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      sig { returns(Image) }
      def current_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      sig { params(current_tag: T.nilable(String)).returns(Image) }
      def previous_version(current_tag = nil)
        raise NotImplementedError, 'please use a Docker::Image subclass'
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
      def registry_metadata_host
        @registry_metadata_host ||= "#{registry_metadata_uri.host}:#{registry_metadata_uri.port}"
      end

      sig { returns(String) }
      def registry_metadata_hostname
        @registry_metadata_host ||= registry_metadata_uri.host
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
        @full_image_uri ||= DockerURI.parse(image_url)
      end

      sig { returns(DockerURI) }
      def registry_metadata_uri
        @registry_metadata_uri ||= DockerURI.parse(
          registry_metadata_url || image_url,
          default_host: DEFAULT_REGISTRY_METADATA_HOST,
          default_port: DEFAULT_REGISTRY_METADATA_PORT
        )
      end

      sig { returns(T::Array[String]) }
      def tags
        [main_tag, *alias_tags].compact
      end

      sig { params(build_args: T::Hash[String, String], docker_args: T::Array[String]).void }
      def build(build_args = {}, docker_args = [])
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      sig { params(tag: String).void }
      def push(tag)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      sig { returns(Docker::CLI) }
      def docker_cli
        @docker_cli ||= Docker::CLI.new
      end

      private

      sig { params(main_tag: String, alias_tags: T::Array[String]).returns(Image) }
      def duplicate_with_tags(main_tag, alias_tags)
        self.class.new(dockerfile, image_url, credentials, registry_metadata_url, main_tag, alias_tags)
      end
    end
  end
end
