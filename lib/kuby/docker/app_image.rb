module Kuby
  module Docker
    class AppImage < ::Kuby::Docker::TimestampedImage
      def build(build_args = {})
        unless ENV.fetch('RAILS_MASTER_KEY', '').empty?
          build_args['RAILS_MASTER_KEY'] = ENV['RAILS_MASTER_KEY']
        end

        super(build_args)
      end
    end
  end
end
