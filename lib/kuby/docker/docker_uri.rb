# typed: strict

module Kuby
  module Docker
    class DockerURI
      # extend T::Sig

      DEFAULT_REGISTRY_HOST = 'docker.io'.freeze
      DEFAULT_REGISTRY_INDEX_HOST = 'index.docker.io'.freeze
      DEFAULT_PORT = 443

      # T::Sig::WithoutRuntime.sig { params(url: String).returns(DockerURI) }
      def self.parse_uri(url)
        parse(
          url,
          default_host: DEFAULT_REGISTRY_HOST,
          default_port: DEFAULT_PORT
        )
      end

      # T::Sig::WithoutRuntime.sig { params(url: String).returns(DockerURI) }
      def self.parse_index_uri(url)
        parse(
          url,
          default_host: DEFAULT_REGISTRY_INDEX_HOST,
          default_port: DEFAULT_PORT
        )
      end

      # T::Sig::WithoutRuntime.sig {
      #   params(
      #     url: String,
      #     default_host: T.nilable(String),
      #     default_port: T.nilable(Integer)
      #   ).returns(DockerURI)
      # }
      def self.parse(url, default_host:, default_port:)
        if idx = url.index('://')
          url = url[(idx + 3)..-1] || ''
        end

        host_port, *path = url.split('/')
        host, port, *path = if host_port =~ /[.:]/
          hst, prt = host_port.split(':')
          [hst, prt || default_port, *path]
        else
          [default_host, default_port, host_port, *path]
        end

        new(host.to_s, port.to_i, (path || []).join('/'))
      end

      # T::Sig::WithoutRuntime.sig { returns(String) }
      attr_reader :host

      # T::Sig::WithoutRuntime.sig { returns(Integer) }
      attr_reader :port

      # T::Sig::WithoutRuntime.sig { returns(String) }
      attr_reader :path

      # T::Sig::WithoutRuntime.sig { params(host: String, port: Integer, path: String).void }
      def initialize(host, port, path)
        @host = host
        @port = port
        @path = path
      end

      # T::Sig::WithoutRuntime.sig { returns(T::Boolean) }
      def has_default_port?
        port == DEFAULT_PORT
      end
    end
  end
end
