# typed: strict

module Kuby
  module Docker
    class DockerURI
      extend T::Sig

      DEFAULT_REGISTRY_HOST = T.let('docker.io'.freeze, String)
      DEFAULT_REGISTRY_PORT = T.let(443, Integer)

      DEFAULT_REGISTRY_INDEX_HOST = T.let('index.docker.io'.freeze, String)
      DEFAULT_REGISTRY_INDEX_PORT = T.let(443, Integer)

      sig { params(url: String).returns(DockerURI) }
      def self.parse_uri(url)
        parse(
          url,
          default_host: DEFAULT_REGISTRY_HOST,
          default_port: DEFAULT_REGISTRY_PORT
        )
      end

      sig { params(url: String).returns(DockerURI) }
      def self.parse_index_uri(url)
        parse(
          url,
          default_host: DEFAULT_REGISTRY_INDEX_HOST,
          default_port: DEFAULT_REGISTRY_INDEX_PORT
        )
      end

      sig {
        params(
          url: String,
          default_host: T.nilable(String),
          default_port: T.nilable(Integer)
        ).returns(DockerURI)
      }
      def self.parse(url, default_host:, default_port:)
        if idx = url.index('://')
          url = url[(idx + 3)..-1] || ''
        end

        host_port, *path = url.split('/')
        host, port, *path = if host_port =~ /[.:]/
          hst, prt = T.must(host_port).split(':')
          [T.must(hst), prt || default_port, *path]
        else
          [default_host, default_port, host_port, *path]
        end

        new(host.to_s, port.to_i, (path || []).join('/'))
      end

      sig { returns(String) }
      attr_reader :host

      sig { returns(Integer) }
      attr_reader :port

      sig { returns(String) }
      attr_reader :path

      sig { params(host: String, port: Integer, path: String).void }
      def initialize(host, port, path)
        @host = host
        @port = port
        @path = path
      end
    end
  end
end
