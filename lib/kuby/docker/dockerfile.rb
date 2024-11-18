# typed: strict

require 'digest'

module Kuby
  module Docker
    class Dockerfile
      extend T::Sig

      class Command
        extend T::Sig

        T::Sig::WithoutRuntime.sig { returns(T::Array[T.any(String, Integer)]) }
        attr_reader :args

        T::Sig::WithoutRuntime.sig { params(args: T::Array[T.any(String, Integer)]).void }
        def initialize(args)
          @args = args
        end

        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s
          args.join(' ')
        end
      end

      class From < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        attr_reader :image_url

        T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
        attr_reader :as

        T::Sig::WithoutRuntime.sig { params(image_url: String, as: T.nilable(String)).void }
        def initialize(image_url, as: nil)
          @image_url = image_url
          @as = as
        end

        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s
          str = "FROM #{image_url}"
          str << " AS #{as}" if as
          str
        end
      end

      class Workdir < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s; "WORKDIR #{super}"; end
      end

      class Env < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s; "ENV #{super}"; end
      end

      class Run < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s; "RUN #{super}"; end
      end

      class Copy < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        attr_reader :source

        T::Sig::WithoutRuntime.sig { returns(String) }
        attr_reader :dest

        T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
        attr_reader :from

        T::Sig::WithoutRuntime.sig { params(source: String, dest: String, from: T.nilable(String)).void }
        def initialize(source, dest, from: nil)
          @source = source
          @dest = dest
          @from = from
        end

        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s
          cmd = ['COPY']
          cmd << "--from=#{from}" if from
          cmd += [source, dest]
          cmd.join(' ')
        end
      end

      class Expose < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s; "EXPOSE #{super}"; end
      end

      class Cmd < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s; "CMD #{super}"; end
      end

      class Arg < Command
        T::Sig::WithoutRuntime.sig { returns(String) }
        def to_s; "ARG #{super}"; end
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[Command]) }
      attr_reader :commands

      T::Sig::WithoutRuntime.sig { returns(Integer) }
      attr_reader :cursor

      T::Sig::WithoutRuntime.sig { void }
      def initialize
        @commands = T.let([], T::Array[Command])
        @cursor = T.let(0, Integer)
      end

      T::Sig::WithoutRuntime.sig { params(image_url: String, as: T.nilable(String)).void }
      def from(image_url, as: nil)
        add From.new(image_url, as: as)
      end

      T::Sig::WithoutRuntime.sig { params(args: String).void }
      def workdir(*args)
        add Workdir.new(args)
      end

      T::Sig::WithoutRuntime.sig { params(args: String).void }
      def env(*args)
        add Env.new(args)
      end

      T::Sig::WithoutRuntime.sig { params(args: String).void }
      def arg(*args)
        add Arg.new(args)
      end

      T::Sig::WithoutRuntime.sig { params(args: String).void }
      def run(*args)
        add Run.new(args)
      end

      T::Sig::WithoutRuntime.sig { params(source: String, dest: String, from: T.nilable(String)).void }
      def copy(source, dest, from: nil)
        add Copy.new(source, dest, from: from)
      end

      T::Sig::WithoutRuntime.sig { params(port: Integer).void }
      def expose(port)
        add Expose.new([port])
      end

      T::Sig::WithoutRuntime.sig { params(args: String).void }
      def cmd(*args)
        add Cmd.new(args)
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def to_s
        # ensure trailing newline
        "#{commands.map(&:to_s).join("\n")}\n"
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def checksum
        Digest::SHA256.hexdigest(to_s)
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[Integer]) }
      def exposed_ports
        commands
          .select { |c| c.is_a?(Expose) }
          .map { |c| T.cast(c.args.first, Integer) }
      end

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      def current_workdir
        found = commands.reverse_each.find do |command|
          command.is_a?(Kuby::Docker::Dockerfile::Workdir)
        end

        T.cast(found.args.first, String) if found
      end

      T::Sig::WithoutRuntime.sig { params(pos: Integer, block: T.proc.void).void }
      def insert_at(pos, &block)
        @cursor = pos
        yield
      ensure
        @cursor = commands.size
      end

      private

      T::Sig::WithoutRuntime.sig { params(cmd: Command).void }
      def add(cmd)
        commands.insert(cursor, cmd)
        @cursor += 1
      end
    end
  end
end
