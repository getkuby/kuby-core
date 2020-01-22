module Kuby
  module Docker
    class Dockerfile
      class Command
        attr_reader :args

        def initialize(*args)
          @args = args
        end

        def to_s
          args.join(' ')
        end
      end

      class From < Command
        def to_s; "FROM #{super}"; end
      end

      class Workdir < Command
        def to_s; "WORKDIR #{super}"; end
      end

      class Env < Command
        def to_s; "ENV #{super}"; end
      end

      class Run < Command
        def to_s; "RUN #{super}"; end
      end

      class Copy < Command
        def to_s; "COPY #{super}"; end
      end

      class Expose < Command
        def to_s; "EXPOSE #{super}"; end
      end

      class Cmd < Command
        def to_s; "CMD #{super}"; end
      end

      attr_reader :commands

      def initialize
        @commands = []
      end

      def from(*args)
        commands << From.new(*args)
      end

      def workdir(*args)
        commands << Workdir.new(*args)
      end

      def env(*args)
        commands << Env.new(*args)
      end

      def run(*args)
        commands << Run.new(*args)
      end

      def copy(*args)
        commands << Copy.new(*args)
      end

      def expose(*args)
        commands << Expose.new(*args)
      end

      def cmd(*args)
        commands << Cmd.new(*args)
      end

      def to_s
        commands.map(&:to_s).join("\n")
      end

      def exposed_ports
        commands
          .select { |c| c.is_a?(Expose) }
          .map { |c| c.args.first }
      end
    end
  end
end
