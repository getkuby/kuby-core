# typed: strict

module Kuby
  module Docker
    class Image
      extend T::Sig

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :identifier

      T::Sig::WithoutRuntime.sig { returns(String) }
      attr_reader :image_url

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :registry_index_url

      T::Sig::WithoutRuntime.sig { returns(Credentials) }
      attr_reader :credentials

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :main_tag

      T::Sig::WithoutRuntime.sig { returns T::Array[String] }
      attr_reader :alias_tags

      T::Sig::WithoutRuntime.sig {
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Dockerfile)),
          image_url: String,
          credentials: Credentials,
          registry_index_url: T.nilable(String),
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      }
      def initialize(dockerfile, image_url, credentials, registry_index_url = nil, main_tag = nil, alias_tags = [])
        @dockerfile = T.let(dockerfile, T.any(Dockerfile, T.proc.returns(Dockerfile)))
        @image_url = T.let(image_url, String)
        @registry_index_url = T.let(registry_index_url, T.nilable(String))
        @credentials = T.let(credentials, Credentials)
        @main_tag = T.let(main_tag, T.nilable(String))
        @alias_tags = T.let(alias_tags, T::Array[String])
        @identifier = T.let(@identifier, T.nilable(String))

        @image_host = T.let(@image_host, T.nilable(String))
        @image_hostname = T.let(@image_hostname, T.nilable(String))
        @registry_index_host = T.let(@registry_index_host, T.nilable(String))
        @registry_index_hostname = T.let(@registry_index_hostname, T.nilable(String))
        @registry_index_uri = T.let(@registry_index_uri, T.nilable(DockerURI))
        @image_repo = T.let(@image_repo, T.nilable(String))
        @full_image_uri = T.let(@full_image_uri, T.nilable(DockerURI))
        @docker_cli = T.let(@docker_cli, T.nilable(Docker::CLI))
      end

      T::Sig::WithoutRuntime.sig { returns(Image) }
      def new_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      T::Sig::WithoutRuntime.sig { returns(Image) }
      def current_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      T::Sig::WithoutRuntime.sig { params(current_tag: T.nilable(String)).returns(Image) }
      def previous_version(current_tag = nil)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      T::Sig::WithoutRuntime.sig { returns(Dockerfile) }
      def dockerfile
        if @dockerfile.respond_to?(:call)
          T.cast(@dockerfile, T.proc.returns(Dockerfile)).call
        else
          T.cast(@dockerfile, Dockerfile)
        end
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def image_host
        @image_host ||= "#{image_uri.host}:#{image_uri.port}"
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def registry_index_host
        @registry_index_host ||= "#{registry_index_uri.host}:#{registry_index_uri.port}"
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def registry_index_hostname
        @registry_index_hostname ||= registry_index_uri.host
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def image_hostname
        @image_hostname ||= image_uri.host
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def image_repo
        @image_repo ||= image_uri.path
      end

      T::Sig::WithoutRuntime.sig { returns(DockerURI) }
      def image_uri
        @full_image_uri ||= DockerURI.parse_uri(image_url)
      end

      T::Sig::WithoutRuntime.sig { returns(DockerURI) }
      def registry_index_uri
        @registry_index_uri ||= DockerURI.parse_index_uri(registry_index_url || image_url)
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      def tags
        [main_tag, *alias_tags].compact
      end

      T::Sig::WithoutRuntime.sig {
        params(
          build_args: T::Hash[String, String],
          docker_args: T::Array[String],
          context: T.nilable(String),
          cache_from: T.nilable(String)
        ).void
      }
      def build(build_args = {}, docker_args = [], context: nil, cache_from: nil)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      T::Sig::WithoutRuntime.sig { params(tag: String).void }
      def push(tag)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      T::Sig::WithoutRuntime.sig { params(tag: String).void }
      def pull(tag)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      T::Sig::WithoutRuntime.sig { returns(Docker::CLI) }
      def docker_cli
        @docker_cli ||= Docker::CLI.new
      end

      private

      T::Sig::WithoutRuntime.sig { params(main_tag: String, alias_tags: T::Array[String]).returns(Image) }
      def duplicate_with_tags(main_tag, alias_tags)
        self.class.new(dockerfile, image_url, credentials, registry_index_url, main_tag, alias_tags)
      end
    end
  end
end
