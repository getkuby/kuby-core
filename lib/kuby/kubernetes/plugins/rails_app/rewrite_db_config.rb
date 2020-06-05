module Kuby
  module Kubernetes
    module Plugins
      module RailsApp
        class RewriteDbConfig
          def apply_to(dockerfile)
            dockerfile.run('bundle exec rake kuby:rails_app:db:rewrite_config')
          end
        end
      end
    end
  end
end
