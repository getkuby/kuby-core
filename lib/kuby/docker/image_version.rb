# typed: strict

module Kuby
  module Docker
    class ImageVersion
      extend T::Sig

      sig { returns(Image) }
      attr_reader :image

      sig { returns(String) }
      attr_reader :main_tag

      sig { returns(T::Array[String]) }
      attr_reader :alias_tags

      sig { params(image: Image, main_tag: String, alias_tags: T::Array[String]).void }
      def initialize(image, main_tag, alias_tags = [])
        @image = T.let(image, Image)
        @main_tag = T.let(main_tag, String)
        @alias_tags = T.let(alias_tags, T::Array[String])

        @docker_cli = T.let(@docker_cli, T.nilable(Docker::CLI))
      end

      sig { params(build_args: T::Hash[String, String], docker_args: T::Array[String], context: T.nilable(String)).void }
      def build(build_args = {}, docker_args = [], context: nil)
        docker_cli.build(self, build_args: build_args, docker_args: docker_args, context: context)
      end

      sig { params(tag: String).void }
      def push(tag)
        docker_cli.push(image.image_url, tag)
      end

      sig { returns(T::Array[String]) }
      def tags
        [main_tag, *alias_tags].compact
      end

      sig { returns(T::Boolean) }
      def exists?
        image.version_strategy.tag_exists?(main_tag)
      end

      sig { params(main_tag_override: String, alias_tag_overrides: T::Array[String]).returns(ImageVersion) }
      def with_tags(main_tag_override, alias_tag_overrides)
        self.class.new(image, main_tag_override, alias_tag_overrides)
      end

      private

      sig { returns(Docker::CLI) }
      def docker_cli
        @docker_cli ||= Docker::CLI.new
      end
    end
  end
end
