# typed: false

module Kuby
  module Docker
    class DockerURI
      DEFAULT_REGISTRY_HOST = 'index.docker.io'.freeze
      DEFAULT_REGISTRY_PORT = 443

      def self.parse(url)
        if idx = url.index('://')
          url = url[(idx + 3)..-1] || ''
        end

        host_port, *path = url.split('/')
        host, port, *path = if host_port =~ /[.:]/
          hst, prt = host_port.split(':')
          [hst, prt || DEFAULT_REGISTRY_PORT, *path]
        else
          [DEFAULT_REGISTRY_HOST, DEFAULT_REGISTRY_PORT, host_port, *path]
        end

        new(host, port.to_i, path.join('/'))
      end

      attr_reader :host, :port, :path

      def initialize(host, port, path)
        @host = host
        @port = port
        @path = path
      end
    end
  end
end
