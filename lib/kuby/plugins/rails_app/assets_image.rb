module Kuby
  module Plugins
    module RailsApp
      class AssetsImage < ::Kuby::Docker::Image
        attr_reader :base_image

        def initialize(base_image, dockerfile, registry_index_url = nil, main_tag = nil, alias_tags = [])
          super(dockerfile, base_image.image_url, base_image.credentials, registry_index_url, main_tag, alias_tags)
          @base_image = base_image
          @identifier = "assets"
        end

        def new_version
          # Asset images track the base image, so return the current version
          # here. There can be no asset image without a base image.
          current_version
        end

        def current_version
          @current_version ||= duplicate_with_annotated_tags(
            base_image.current_version
          )
        end

        def previous_version
          @previous_version ||= duplicate_with_annotated_tags(
            base_image.previous_version
          )
        end

        def build(build_args = {}, docker_args = [])
          unless ENV.fetch('RAILS_MASTER_KEY', '').empty?
            build_args['RAILS_MASTER_KEY'] = ENV['RAILS_MASTER_KEY']
          end

          docker_cli.build(current_version, build_args: build_args, docker_args: docker_args)
        end

        def push(tag)
          docker_cli.push(image_url, tag)
        end

        private

        def duplicate_with_annotated_tags(image)
          self.class.new(
            base_image,
            dockerfile,
            registry_index_url,
            annotate_tag(image.main_tag),
            image.alias_tags.map { |at| annotate_tag(at) }
          )
        end

        def annotate_tag(tag)
          "#{tag}-assets"
        end
      end
    end
  end
end
