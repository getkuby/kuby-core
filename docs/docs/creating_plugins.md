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
1. `setup()`: Called during setup, i.e. whenever the `kuby setup` command is executed. Since `kuby setup` can be executed multiple times during the lifetime of an application (eg. when new plugins are added, etc), `#setup` routines should be idempotent.
1. `remove()`: Should do the opposite of whatever `setup()` does. A plugin's `#remove` routine is only invoked when the special `kuby plugin remove [plugin name]` command is executed.
1. `resources()`: Returns an array of `KubeDSL::DSLObject` objects. See below for additional information regarding creating Kubernetes resource objects.
1. `docker_images()`: Returns an array of `Kuby::Docker::Image` objects. These images will be built on `kuby build` and pushed on `kuby push`. See below for additional information regarding creating Docker images.
1. `after_initialize()`: Called by the base `Kuby::Plugin#initialize` method. Designed to avoid forcing the plugin author call `super` in `#initialize`.
1. `self.task_dirs()`: Returns an array of paths containing .rake files. Through this mechanism plugins can define Rake tasks that can be executed using the `kuby` command.

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

## Creating Additional Kubernetes Resources

Kuby uses [KubeDSL](https://github.com/getkuby/kube-dsl) to define Kubernetes resources in Ruby code. KubeDSL is a complete representation of the Kubernetes schema, so it's possible to create any kind of Kubernetes resource. For example, here's how to create a Kubernetes "config map". Config maps can be used to store bits of config data (or even the contents of entire files) that can be subsequently attached to pods and made available to your application:

```ruby
KubeDSL.config_map do
  metadata do
    # The name of this config map. Must be unique within the
    # given namespace.
    name 'my-config-map'

    # This is how to get the name of the namespace your app runs in.
    namespace Kuby.environment.kubernetes.namespace.metadata.name
  end

  data do
    add 'VAR_NAME', 'VAR_VALUE'
    # etc, etc
  end
end
```

This config map object will be deployed if it is returned it from the `#resources` method in your plugin:

```ruby
class MyPlugin < Kuby::Plugin
  def resources
    [config_map]
  end

  private

  def config_map
    @config_map ||= KubeDSL.config_map do
      # (see above)
    end
  end
end
```

## Custom Resource Definitions (CRDs)

A number of the plugins in the Kuby ecosystem contain DSL objects built from Custom Resource Definitions, or CRDs. CRDs are Kubernetes API extensions. They augment the set of objects in the Kubernetes API with custom ones defined by 3rd-party developers. For example, the CockroachDB Kubernetes operator defines a `CrdbCluster` object. The operator listens for objects of type `CrdbCluster` and acts accordingly, creating the necessary resources in the cluster to satisfy the object's properties.

See the Rakefiles in [kuby-crdb](https://github.com/getkuby/kuby-crdb) and [kuby-cert-manager](https://github.com/getkuby/kuby-cert-manager) for examples of Kuby plugins that make use of DSL objects generated from CRDs.

## Specifying Additional Docker Images

As mentioned above, plugins can define additional Docker images that will be built and pushed on `kuby build` and `kuby push`, as well as listed in the output of `kuby dockerfiles`, etc.

In Kuby, Docker images are defined via classes that inherit from a subclass of `Kuby::Docker::Image`, most often `Kuby::Docker::TimestampedImage`. The `TimestampedImage` class versions images by using timestamped Docker tags. These tags can be programmatically ordered so as to know which image is the most recent, second most recent, etc.

### Creating a Dockerfile

Before creating an `Image` subclass, you'll need to create a `Kuby::Docker::Dockerfile` instance. For a complete list of the supported directives, see the [source code](https://github.com/getkuby/kuby-core/blob/c4f5b1fd1d7cc6ff4532f7904b2462ce3e06d110/lib/kuby/docker/dockerfile.rb#L117) in kuby-core.

```ruby
df = Kuby::Docker::Dockerfile.new
df.from('ruby:3.1.0')
df.cmd('ruby -e "puts \'Hello, world!\'"')
```

### Creating an Image

Next, create an instance of `TimestampedImage`:

```ruby
image = Kuby::Docker::TimestampedImage.new(
  # the dockerfile instance
  df,

  # the registry URL for this image
  'docker.pkg.github.com/<username>/<repo>/<image-name>',

  # the Docker registry index URL, only needed if the Docker index
  # and pull/push APIs are served using different URLs
  nil,

  # the tag to use
  'latest',

  # an array of alias tags to tag the image with
  ['foobar']
)
```

### Exposing the Image

Finally, return the image from your plugin:

```ruby
class MyPlugin < Kuby::Plugin
  def docker_images
    [image]
  end

  private

  def image
    @image ||= Kuby::Docker::TimestampedImage.new(...) # the code from above
  end
end
```

Running `bundle exec kuby -e production build` should now build your custom image as well as the usual ones.