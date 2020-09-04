module Kuby
  module Docker
    class LocalTags
      attr_reader :cli, :metadata

      def initialize(cli, metadata)
        @cli = cli
        @metadata = metadata
      end

      def tags
        images = cli.images(metadata.image_url)
        images.map { |image| image[:tag] }
      end

      def latest_tags
        # find "latest" tag
        images = cli.images(metadata.image_url)
        latest = images.find { |image| image[:tag] == Tags::LATEST }

        unless latest
          raise MissingTagError.new(Tags::LATEST)
        end

        # find all tags that point to the same image as 'latest'
        images.each_with_object([]) do |image_data, tags|
          if image_data[:id] == latest[:id]
            tags << image_data[:tag]
          end
        end
      end

      def timestamp_tags
        tags.map { |t| TimestampTag.try_parse(t) }.compact
      end

      def latest_timestamp_tag
        @latest_timestamp_tag ||= timestamp_tags.sort.last
      end
    end
  end
end
