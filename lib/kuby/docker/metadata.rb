module Kuby
  module Docker
    class Metadata
      DEFAULT_DISTRO = [:debian].freeze
      DEFAULT_DISTRO_VERSIONS = { alpine: '3.11' }.freeze

      attr_accessor :image_url
      attr_reader :definition, :distro

      def initialize(definition)
        @definition = definition
        @tags = []
      end

      def image_url
        @image_url || default_image_url
      end

      def tags
        @tags.empty? ? default_tags : @tags
      end

      def distro=(distro_tuple)
        @distro = Array(distro_tuple)
      end

      def distro_name
        (distro || DEFAULT_DISTRO)[0]
      end

      def distro_version
        (distro || DEFAULT_DISTRO)[1] || DEFAULT_DISTRO_VERSIONS[distro_name]
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
