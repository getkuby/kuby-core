module Kuby
  module Docker
    class Image
      attr_reader :dockerfile, :image_url, :tags

      def initialize(dockerfile, image_url, tags)
        @dockerfile = dockerfile
        @image_url = image_url
        @tags = tags
      end
    end
  end
end
