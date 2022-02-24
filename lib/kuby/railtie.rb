# typed: false
require 'logger'
require 'rails/railtie'

module Kuby
  class Railtie < ::Rails::Railtie
    initializer 'kuby.health_check_middleware' do |app|
      app.middleware.use Kuby::Middleware::HealthCheck
    end
  end
end
