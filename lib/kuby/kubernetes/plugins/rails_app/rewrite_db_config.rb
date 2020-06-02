module Kuby
  module Kubernetes
    module Plugins
      class RailsApp < Plugin
        class RewriteDbConfig
          def apply_to(dockerfile)
            dockerfile.run('bundle exec rake kuby:rails_app:db:rewrite_config')
          end
        end
      end
    end
  end
end
