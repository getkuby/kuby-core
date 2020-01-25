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
        attr_reader :image_url, :as

        def initialize(image_url, as: nil)
          @image_url = image_url
          @as = as
        end

        def to_s
          str = "FROM #{image_url}"
          str << " AS #{as}" if as
          str
        end
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
        attr_reader :source, :dest, :from

        def initialize(source, dest, from: nil)
          @source = source
          @dest = dest
          @from = from
        end

        def to_s
          cmd = ['COPY']
          cmd << "--from=#{from}" if from
          cmd += [source, dest]
          cmd.join(' ')
        end
      end

      class Expose < Command
        def to_s; "EXPOSE #{super}"; end
      end

      class Cmd < Command
        def to_s; "CMD #{super}"; end
      end

      attr_reader :commands, :cursor

      def initialize
        @commands = []
        @cursor = 0
      end

      def from(*args)
        add From.new(*args)
      end

      def workdir(*args)
        add Workdir.new(*args)
      end

      def env(*args)
        add Env.new(*args)
      end

      def run(*args)
        add Run.new(*args)
      end

      def copy(*args)
        add Copy.new(*args)
      end

      def expose(*args)
        add Expose.new(*args)
      end

      def cmd(*args)
        add Cmd.new(*args)
      end

      def to_s
        commands.map(&:to_s).join("\n")
      end

      def exposed_ports
        commands
          .select { |c| c.is_a?(Expose) }
          .map { |c| c.args.first }
      end

      def insert_at(pos)
        @cursor = pos
        yield
      ensure
        @cursor = commands.size
      end

      private

      def add(cmd)
        commands.insert(cursor, cmd)
        @cursor += 1
      end
    end
  end
end
