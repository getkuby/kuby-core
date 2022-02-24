# typed: strict

module Kuby
  module Plugins
    module RailsApp
      class AssetsImage < Kuby::Docker::Image
        extend T::Sig

        sig { returns(Docker::Image) }
        attr_reader :app_image

        sig { params(app_image: Docker::Image).void }
        def initialize(app_image)
          super(app_image.dockerfile, app_image.image_url, app_image.credentials, app_image.registry_index_url)

          @app_image = T.let(app_image, Docker::Image)
          @new_version = T.let(@new_version, T.nilable(Docker::ImageVersion))
          @current_version = T.let(@current_version, T.nilable(Docker::ImageVersion))
          @previous_version = T.let(@previous_version, T.nilable(Docker::ImageVersion))
        end

        sig { returns(String) }
        def identifier
          'assets'.freeze
        end

        sig { returns(Docker::ImageVersion) }
        def new_version
          # asset images track the app image
          @new_version ||= image_with_annotated_tags(
            app_image.new_version.exists? ? app_image.new_version : app_image.current_version
          )
        end

        sig { returns(Docker::ImageVersion) }
        def current_version
          @current_version ||= image_with_annotated_tags(
            app_image.current_version
          )
        end

        sig { returns(Docker::ImageVersion) }
        def previous_version
          @previous_version ||= image_with_annotated_tags(
            app_image.previous_version
          )
        end

        private

        sig { params(image: Docker::ImageVersion).returns(Docker::ImageVersion) }
        def image_with_annotated_tags(image)
          image.with_tags(
            annotate_tag(image.main_tag),
            annotate_tags(image.alias_tags)
          )
        end

        sig { params(tags: T::Array[String]).returns(T::Array[String]) }
        def annotate_tags(tags)
          tags.map { |t| annotate_tag(t) }
        end

        sig { params(tag: String).returns(String) }
        def annotate_tag(tag)
          "#{tag}-assets"
        end
      end
    end
  end
end
