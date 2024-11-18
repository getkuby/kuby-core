# typed: strict

module Kuby
  class Definition
    # extend T::Sig

    # T::Sig::WithoutRuntime.sig { returns(String) }
    attr_reader :app_name

    # T::Sig::WithoutRuntime.sig { params(app_name: String, block: T.nilable(T.proc.void)).void }
    def initialize(app_name, &block)
      @app_name = app_name
      # @environments = T.let(@environments, T.nilable(T::Hash[Symbol, Environment]))
    end

    # T::Sig::WithoutRuntime.sig {
    #   params(
    #     name: Symbol,
    #     block: T.nilable(T.proc.void)
    #   ).returns(Kuby::Environment)
    # }
    def environment(name = Kuby.env, &block)
      name = name.to_s

      environments[name] ||= Environment.new(name, self)

      if block_given?
        environments[name].instance_eval(&block)
      end

      environments[name]
    end

    # T::Sig::WithoutRuntime.sig { returns(T::Hash[Symbol, Kuby::Environment]) }
    def environments
      @environments ||= {}
    end
  end
end
