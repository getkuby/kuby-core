require 'uri'

module Kuby
  module Docker
    class Metadata
      DEFAULT_DISTRO = :debian
      DEFAULT_REGISTRY_HOST = 'https://docker.io'.freeze
      LATEST_TAG = 'latest'

      attr_accessor :image_url
      attr_reader :definition, :distro

      def initialize(definition)
        @definition = definition
        @tags = []
      end

      def image_url
        @image_url || default_image_url
      end

      def image_host
        @image_host ||= if image_url.include?('/')
          uri = parse_url(image_url)
          "#{uri.scheme}://#{uri.host}"
        else
          DEFAULT_REGISTRY_HOST
        end
      end

      def image_repo
        @image_repo ||= if image_url.include?('/')
          parse_url(image_url).path.sub(/\A\//, '')
        else
          image_url
        end
      end

      def tags
        @tags.empty? ? default_tags : @tags
      end

      def tag
        @tag ||= begin
          t = ENV.fetch('KUBY_DOCKER_TAG') do
            definition.docker.tags.latest_timestamp_tag&.to_s
          end

          unless t
            raise MissingTagError, 'could not find latest timestamped tag'
          end

          t
        end
      end

      def image_with_tag
        @image_with_tag ||= "#{image_url}:#{tag}"
      end

      def distro=(distro_name)
        @distro = distro_name
      end

      private

      def default_image_url
        # assuming dockerhub by not specifying full url
        @default_image_url ||= definition.app_name.downcase
      end

      def default_tags
        @default_tags ||= [
          TimestampTag.new(Time.now).to_s, LATEST_TAG
        ]
      end

      def parse_url(url)
        uri = URI.parse(url)
        return uri if uri.scheme

        # force a scheme because URI.parse won't work properly without one
        URI.parse("https://#{url}")
      end
    end
  end
end
