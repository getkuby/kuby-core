module Kuby
  module Docker
    class Metadata
      DEFAULT_DISTRO = :debian
      DEFAULT_REGISTRY_HOST = 'docker.io'.freeze

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
        if image_url.include?('/')
          image_url.split('/').first
        else
          DEFAULT_REGISTRY_HOST
        end
      end

      def tags
        @tags.empty? ? default_tags : @tags
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
          Time.now.strftime('%Y%m%d%H%M%S'), 'latest'
        ]
      end
    end
  end
end
