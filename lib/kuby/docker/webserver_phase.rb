module Kuby
  module Docker
    class WebserverPhase < Phase
      class Puma
        attr_reader :phase

        def initialize(phase)
          @phase = phase
        end

        def apply_to(dockerfile)
          dockerfile.cmd(
            'puma',
            '--workers', '4',
            '--bind', 'tcp://0.0.0.0',
            '--port', phase.port,
            '--pidfile', './server.pid',
            './config.ru'
          )

          dockerfile.expose(phase.port)
        end
      end

      DEFAULT_PORT = 8080
      WEBSERVER_MAP = { puma: Puma }.freeze

      attr_accessor :port, :webserver

      def apply_to(dockerfile)
        ws = webserver || default_webserver
        ws_class = WEBSERVER_MAP[ws]
        raise "No webserver named #{ws}" unless ws_class

        ws_class.new(self).apply_to(dockerfile)
      end

      def port
        @port || DEFAULT_PORT
      end

      private

      def default_webserver
        if Gem.loaded_specs.include?('puma')
          :puma
        end
      end
    end
  end
end
