require 'uri'

module Kuby
  module Docker
    class Metadata
      DEFAULT_DISTRO = :debian
      DEFAULT_REGISTRY_HOST = 'https://www.docker.com'.freeze
      DEFAULT_REGISTRY_SCHEME = 'https'
      LATEST_TAG = 'latest'

      attr_accessor :image_url
      attr_reader :environment

      def initialize(environment)
        @environment = environment
        @tags = []
      end

      def image_url
        @image_url || default_image_url
      end

      def image_host
        @image_host ||= "#{full_image_uri.scheme}://#{full_image_uri.host}"
      end

      def image_hostname
        @image_hostname ||= URI(image_host).host
      end

      def image_repo
        @image_repo ||= full_image_uri.path.sub(/\A[\/]+/, '')
      end

      def tags
        @tags.empty? ? default_tags : @tags
      end

      def tag
        t = ENV.fetch('KUBY_DOCKER_TAG') do
          environment.docker.tags.latest_timestamp_tag
        end

        unless t
          raise MissingTagError, 'could not find latest timestamped tag'
        end

        t.to_s
      end

      def previous_tag(current_tag)
        t = environment.docker.tags.previous_timestamp_tag(current_tag)

        unless t
          raise MissingTagError, 'could not find previous timestamped tag'
        end

        t.to_s
      end

      def distro
        @distro || DEFAULT_DISTRO
      end

      def distro=(distro_name)
        @distro = distro_name
      end

      private

      def full_image_uri
        @full_image_uri ||= if image_url.include?('://')
          URI.parse(image_url)
        elsif image_url =~ /\A[^.]+\.[^\/]+\//
          URI.parse("#{DEFAULT_REGISTRY_SCHEME}://#{image_url}")
        else
          URI.parse("#{DEFAULT_REGISTRY_HOST}/#{image_url.sub(/\A[\/]+/, '')}")
        end
      end

      def default_image_url
        # assuming dockerhub by not specifying full url
        @default_image_url ||= environment.app_name.downcase
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
        URI.parse("#{DEFAULT_REGISTRY_SCHEME}://#{url}")
      end
    end
  end
end
