# typed: strict

module Kuby
  class Definition
    extend T::Sig

    sig { returns(String) }
    attr_reader :app_name

    sig { params(app_name: String, block: T.nilable(T.proc.void)).void }
    def initialize(app_name, &block)
      @app_name = app_name
      @environments = T.let(@environments, T.nilable(T::Hash[Symbol, Environment]))
    end

    sig {
      params(
        name: Symbol,
        block: T.nilable(T.proc.void)
      ).returns(Environment)
    }
    def environment(name = Kuby.env, &block)
      name = name.to_s

      environments[name] ||= Environment.new(name, self)

      if block_given?
        environments[name].instance_eval(&block)
      end

      T.must(environments[name])
    end

    sig { returns(T::Hash[Symbol, Environment]) }
    def environments
      @environments ||= {}
    end
  end
end
