require 'kuby/railtie'

module Kuby
  autoload :Definition,  'kuby/definition'
  autoload :Docker,      'kuby/docker'
  autoload :Kubernetes,  'kuby/kubernetes'
  autoload :ValueFields, 'kuby/value_fields'

  class << self
    attr_reader :definition

    def define(app = Rails.application, &block)
      @definition = Definition.new(app, &block)
    end

    def docker_cli
      @docker_cli ||= Docker::CLI.new
    end
  end
end
