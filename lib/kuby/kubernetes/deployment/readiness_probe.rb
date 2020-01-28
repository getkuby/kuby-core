module Kuby
  module Kubernetes
    class Deployment
      class ReadinessProbe
        class HttpGet
          extend ValueFields

          value_fields :path, :port, :scheme

          def serialize
            { path: path, port: port, scheme: scheme }
          end
        end

        extend ValueFields

        value_fields :success_threshold, :failure_threshold
        value_fields :initial_delay_seconds, :period_seconds, :timeout_seconds
        object_field(:http_get) { HttpGet.new }

        def serialize
          {
            successThreshold: success_threshold,
            failureThreshold: failure_threshold,
            initialDelaySeconds: initial_delay_seconds,
            periodSeconds: period_seconds,
            timeoutSeconds: timeout_seconds,
            httpGet: http_get.serialize
          }
        end
      end
    end
  end
end
