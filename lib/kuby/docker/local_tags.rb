# typed: strict

module Kuby
  module Docker
    class LocalTags
      extend T::Sig

      T::Sig::WithoutRuntime.sig { returns CLI }
      attr_reader :cli

      T::Sig::WithoutRuntime.sig { returns(String) }
      attr_reader :image_url

      T::Sig::WithoutRuntime.sig {
        params(
          cli: CLI,
          image_url: String
        )
        .void
      }
      def initialize(cli, image_url)
        @cli = cli
        @image_url = image_url
        @latest_timestamp_tag = T.let(@latest_timestamp_tag, T.nilable(TimestampTag))
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      def tags
        images = cli.images(image_url)
        images.map { |image| T.must(image[:tag]) }
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      def latest_tags
        # find "latest" tag
        images = cli.images(image_url)
        latest = images.find { |image| image[:tag] == Kuby::Docker::LATEST_TAG }

        unless latest
          raise MissingTagError, "could not find tag #{Kuby::Docker::LATEST_TAG}"
        end

        # find all tags that point to the same image as 'latest'
        images.each_with_object([]) do |image_data, tags|
          if image_data[:id] == latest[:id]
            tags << image_data[:tag]
          end
        end
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[TimestampTag]) }
      def timestamp_tags
        tags.map { |t| TimestampTag.try_parse(t) }.compact
      end

      T::Sig::WithoutRuntime.sig { returns(T.nilable(TimestampTag)) }
      def latest_timestamp_tag
        @latest_timestamp_tag ||= timestamp_tags.sort.last
      end
    end
  end
end
