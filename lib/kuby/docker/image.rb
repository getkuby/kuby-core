module Kuby
  module Docker
    class Image
      attr_reader :image_url, :credentials, :main_tag, :alias_tags

      def initialize(dockerfile, image_url, credentials, main_tag = nil, alias_tags = [])
        @dockerfile = dockerfile
        @image_url = image_url
        @credentials = credentials
        @main_tag = main_tag
        @alias_tags = alias_tags
      end

      def new_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      def current_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      def previous_version
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      def dockerfile
        @dockerfile.respond_to?(:call) ? @dockerfile.call : @dockerfile
      end

      def image_host
        @image_host ||= "#{image_uri.host}:#{image_uri.port}"
      end

      def image_hostname
        @image_hostname ||= image_uri.host
      end

      def image_repo
        @image_repo ||= image_uri.path
      end

      def image_uri
        @full_image_uri ||= DockerURI.parse(image_url)
      end

      def tags
        [main_tag, *alias_tags]
      end

      def build(*)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      def push(*)
        raise NotImplementedError, 'please use a Docker::Image subclass'
      end

      def docker_cli
        @docker_cli ||= Docker::CLI.new
      end

      private

      def duplicate_with_tags(main_tag, alias_tags)
        self.class.new(dockerfile, image_url, credentials, main_tag, alias_tags)
      end
    end
  end
end
