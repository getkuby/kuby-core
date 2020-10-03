---
id: customizing-kubernetes-resources
title: Customizing Kubernetes Resources
sidebar_label: Customizing Kubernetes Resources
slug: /customizing-kubernetes-resources
---

In Kubernetes, everything is a resource. Resources generally have a "kind" (eg. "ConfigMap", "Namespace", etc), and a unique name. Kubernetes resources are usually stored as flat .yml or .json files and applied via the Kubernetes CLI, `kubectl` (vocalized as "kube control", or "kube cuttle"). However, Kuby does things a little differently - resources are defined in Ruby code using the [KubeDSL gem](https://github.com/getkuby/kube-dsl). Kuby defines around 10 resources for a standard Rails app, which are summarized below.

1. **Namepace**: A Kubernetes namespace inside which all other resources are defined.
1. **ServiceAccount**: An account permitted to make changes inside the namespace.
1. **Service**: Defines an HTTP interface to your app and defines which ports should be exposed.
1. **ConfigMaps**: Contains configuration data your app needs to run, usually key/value pairs.
1. **Secrets**: Contains app "secrets", i.e. sensitive configuration data like 3rd party API keys, passwords, etc. By default, this only contains the contents of `RAILS_MASTER_KEY`. A separate secret contains Docker image pull credentials.
1. **Deployment**: Specifies how to deploy your app. Includes configuration for creating and migrating the database, as well as where to get the Docker image and how to safely restart the Rails server without dropping requests.
1. **Ingress**: Defines how connections to your app will be made from the outside world.

Some functionality can be configured easily with flags or configuration options. For example, here's how to disable TLS for your Rails app (it's turned on by default):

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      plugin :rails_app do
        tls_enabled false
      end
    end
  end
end
```

You can also modify resources directly, since most of Kuby's resources are exposed publicly and are designed to be mutable. For example, here's how to change the name of your app's namespace object:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      plugin :rails_app do
        namespace do
          metadata do
            name "helloworld"
          end
        end
      end
    end
  end
end
```
