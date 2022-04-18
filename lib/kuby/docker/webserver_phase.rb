# typed: strict

module Kuby
  module Docker
    class WebserverPhase < Layer
      extend T::Sig

      class Webserver
        extend T::Sig
        extend T::Helpers

        abstract!

        T::Sig::WithoutRuntime.sig { returns(WebserverPhase) }
        attr_reader :phase

        T::Sig::WithoutRuntime.sig { params(phase: WebserverPhase).void }
        def initialize(phase)
          @phase = phase
        end

        T::Sig::WithoutRuntime.sig { abstract.params(dockerfile: Dockerfile).void }
        def apply_to(dockerfile); end
      end

      class Puma < Webserver
        T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
        def apply_to(dockerfile)
          dockerfile.cmd(
            'puma',
            '--workers', '4',
            '--bind', 'tcp://0.0.0.0',
            '--port', phase.port.to_s,
            '--pidfile', './server.pid',
            './config.ru'
          )

          dockerfile.expose(phase.port)
        end
      end

      DEFAULT_PORT = T.let(8080, Integer)
      WEBSERVER_MAP = T.let({ puma: Puma }.freeze, T::Hash[Symbol, T.class_of(Webserver)])

      T::Sig::WithoutRuntime.sig { params(port: Integer).returns(String) }
      attr_writer :port

      T::Sig::WithoutRuntime.sig { returns(T.nilable(Symbol)) }
      attr_reader :webserver

      T::Sig::WithoutRuntime.sig { params(webserver: Symbol).returns(String) }
      attr_writer :webserver

      T::Sig::WithoutRuntime.sig { override.params(environment: Environment).void }
      def initialize(environment)
        super

        @port = T.let(@port, T.nilable(Integer))
        @webserver = T.let(@webserver, T.nilable(Symbol))
      end

      T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        ws = webserver || default_webserver
        ws_class = WEBSERVER_MAP[T.must(ws)]
        raise "No webserver named #{ws}" unless ws_class

        ws_class.new(self).apply_to(dockerfile)
      end

      T::Sig::WithoutRuntime.sig { returns(Integer) }
      def port
        @port || DEFAULT_PORT
      end

      private

      T::Sig::WithoutRuntime.sig { returns(T.nilable(Symbol)) }
      def default_webserver
        if Gem.loaded_specs.include?('puma')
          :puma
        end
      end
    end
  end
end
