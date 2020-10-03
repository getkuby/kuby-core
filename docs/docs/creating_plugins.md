---
id: creating-plugins
title: Creating Your Own Plugins
sidebar_label: Creating Your Own Plugins
slug: /creating-plugins
---

Kuby features a plugin system that makes it easy to add your own functionality. In fact, much of Kuby's own feature set is implemented as a series of plugins.

## Anatomy of a Plugin

Plugins are just Ruby classes that inherit from `Kuby::Plugin`. The plugin interface, i.e. the methods plugins are expected to respond to, are summarized below.

1. `configure(&block)`: Called when the plugin is added to a Kuby environment. In other words:

    ```ruby
    Kuby.define('my-app') do
      environment(:production) do
        add_plugin(:my_plugin) do
          # at this point, the plugin's `configure' method is called
          # and handed this block
        end
      end
    end
    ```
1. `setup()`: Called during setup, i.e. whenever the `kuby setup` command is executed.
1. `resources()`: Expected to return an array of `KubeDSL::DSLObject` objects. See below for additional information regarding creating custom Kubernetes resource objects.

## Registering Your Plugin

Plugins must be registered with Kuby's plugin system before they can be used. Register your plugin like so:

```ruby
Kuby.register_plugin(:my_plugin, MyPlugin)
```

## Plugin Lifecycle Methods

In addition to the methods described above, plugins should also respond to a series of lifecycle methods summarized below.

1. `after_configuration()`: Called after all plugins have been configured.
1. `before_setup()`: Called before any plugins have been setup.
1. `after_setup()`: Called after all plugins have been setup.
1. `before_deploy(manifest)`: Called before deploying any resources. The `manifest` argument is an instance of `Kuby::Kubernetes::Manifest` and contains a list of all the Kubernetes resources Kuby intends to deploy.
1. `after_deploy(manifest)`: Called after deploying all resources. The `manifest` argument is an instance of `Kuby::Kubernetes::Manifest` and contains a list of all the Kubernetes resources Kuby has just deployed.

## Creating Custom Resources

Kuby uses [KubeDSL](https://github.com/getkuby/kube-dsl) to define Kubernetes resources in Ruby code. KubeDSL is a complete representation of the Kubernetes schema, so it's possible to create any kind of Kubernetes resource. For example, here's a snippet of the code inside the Rails app plugin that creates a `ServiceAccount`:

```ruby
spec = self

KubeDSL.service_account do
  metadata do
    name "#{spec.selector_app}-sa"
    namespace spec.namespace.metadata.name

    labels do
      add :app, spec.selector_app
      add :role, spec.role
    end
  end
end
```

For those resources that are not part of the standard Kubernetes schema (i.e. custom resource definitions or CRDs), use KubeDSL to define custom objects. Here's an example from the cert-manager plugin.

```ruby
class ClusterIssuer < KubeDSL::DSLObject
  object_field(:metadata) { KubeDSL::DSL::Meta::V1::ObjectMeta.new }
  object_field(:spec) { ClusterIssuerSpec.new }

  def serialize
    {}.tap do |result|
      result[:apiVersion] = "cert-manager.io/v1alpha2"
      result[:kind] = "ClusterIssuer"
      result[:metadata] = metadata.serialize
      result[:spec] = spec.serialize
    end
  end

  def kind_sym
    :cluster_issuer
  end
end
```

The cert-manager plugin includes an instance of this new `ClusterIssuer` object in its list of Kubernetes resources. Here's an (abbreviated) version of the cert-manager plugin to show a complete example:

```ruby
class CertManager < Kuby::Plugin
  def cluster_issuer
    @cluster_issuer ||= ClusterIssuer.new do
      metadata do
        name 'production-cert'
        namespace 'cert-manager'
      end

      #  rest omitted for brevity
    end
  end

  def resources
    [cluster_issuer]
  end
end

Kuby.register_plugin(:cert_manager, CertManager)
```
