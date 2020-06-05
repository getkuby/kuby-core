module Kuby
  module Kubernetes
    module Plugins
      module RailsApp
        autoload :Database,        'kuby/kubernetes/plugins/rails_app/database'
        autoload :MySQL,           'kuby/kubernetes/plugins/rails_app/mysql'
        autoload :Plugin,          'kuby/kubernetes/plugins/rails_app/plugin'
        autoload :Postgres,        'kuby/kubernetes/plugins/rails_app/postgres'
        autoload :RewriteDbConfig, 'kuby/kubernetes/plugins/rails_app/rewrite_db_config'
        autoload :Sqlite,          'kuby/kubernetes/plugins/rails_app/sqlite'
      end
    end
  end
end

load File.expand_path(File.join('rails_app', 'tasks.rake'), __dir__)
