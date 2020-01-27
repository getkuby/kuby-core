module Kuby
  module ValueFields
    def value_fields(*fields)
      fields.each do |field|
        define_method(field) do |*args|
          if args.empty?
            instance_variable_get(:"@#{field}")
          else
            instance_variable_set(:"@#{field}", args.first)
          end
        end
      end
    end

    def object_field(field, &field_block)
      define_method(field) do |&block|
        ivar = :"@#{field}"
        val = instance_variable_get(ivar)

        unless val
          val = field_block.call
          instance_variable_set(ivar, val)
        end

        val.instance_exec(&block) if block
        val
      end
    end

    def array_field(field, accessor = nil, &field_block)
      accessor ||= field.to_s.pluralize.to_sym

      define_method(field) do |&block|
        ivar = :"@#{accessor}"
        arr = instance_variable_get(ivar)

        unless arr
          arr = []
          instance_variable_set(ivar, arr)
        end

        new_val = field_block.call
        new_val.instance_eval(&block) if block
        arr << new_val
      end

      define_method(accessor) do
        ivar = :"@#{accessor}"
        arr = instance_variable_get(ivar)

        unless arr
          arr = []
          instance_variable_set(ivar, arr)
        end

        arr
      end
    end
  end
end
