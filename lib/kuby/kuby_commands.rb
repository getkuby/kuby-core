require 'kuby/gli'
require 'kuby/version'

module Kuby
  class KubyCommands
    extend Kuby::GLI::App

    program_desc 'Kuby command-line interface. Kuby is a convention '\
      'over configuration approach for running Rails apps in Kubernetes.'

    version Kuby::VERSION

    subcommand_option_handling :normal
    arguments :strict

    desc 'The Kuby environment to use. Overrides KUBY_ENV.'
    flag [:e, :environment], type: String, required: false

    desc 'Path to your Kuby config file. Overrides KUBY_CONFIG.'
    default_value './kuby.rb'
    flag [:c, :config]

    pre do |global_options, options, args|
      require 'rubygems'
      require 'bundler'

      Bundler.setup

      require 'kuby'

      Kuby.env = global_options[:environment] if global_options[:environment]
      Kuby.load!(global_options[:config])
    end

    def self.tasks
      Kuby::Tasks.new(Kuby.definition.environment)
    end

    # These are only stubs included to fill out the help screens. Rails
    # commands are handled by the RailsCommands class.
    desc 'Run a Rails command'
    command :rails do |c|
      c.desc 'Run the rails server (run `rails server --help` for options)'
      c.command [:server, :s] do
      end
    end

    desc 'Build the Docker image'
    command :build do |c|
      c.action do |global_options, options, args|
        tasks.build
      end
    end

    desc 'Push the Docker image to the configured registry'
    command :push do |c|
      c.action do |global_options, options, args|
        tasks.push
      end
    end

    desc 'Get your Kubernetes cluster ready for deployments'
    command :setup do |c|
      c.action do |global_options, options, args|
        tasks.setup
      end
    end

    desc 'Print the effective Dockerfile used to build the Docker image'
    command :dockerfile do |c|
      c.action do |global_options, options, args|
        tasks.print_dockerfile
      end
    end

    desc 'Deploy the application'
    command :deploy do |c|
      c.action do |global_options, options, args|
        tasks.deploy
      end
    end
  end
end
