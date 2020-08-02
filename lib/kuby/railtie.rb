require 'logger'
require 'rails/railtie'

module Kuby
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path(File.join('tasks', 'kuby.rake'), __dir__)
    end

    initializer 'kuby.health_check_middleware' do |app|
      app.middleware.use Kuby::Middleware::HealthCheck
    end
  end
end
