---
id: customizing-docker-build
title: Customizing the Docker Build
sidebar_label: Customizing the Docker Build
slug: /customizing-docker-build
---

We've already seen the standard way to configure Kuby's Docker component (i.e. the `docker do ... end` section), but there's a lot more you can do.

## Installing Additional Packages

Kuby officially supports the Debian and Alpine distros of Linux for Docker images.

Let's install imagemagick as an example. First, we'll need to register the imagemagick package with Kuby. It just so happens both the Debian and Alpine Linux distros use the same name for their imagemagick package, meaning we can define using just its name.

Next, we tell Kuby to install imagemagick in the `docker` section of our Kuby config:

```ruby
Kuby.register_package('imagemagick')

Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.add('imagemagick')
    end
  end
end
```

If the package we want to install has a different name under each of the Linux distros, register it using a hash instead. Let's say we want to install the `dig` command-line utility. In Debian, we'd need to install the `dnsutils` package, but in Alpine we'd need `bind-tools`.

```ruby
Kuby.register_package('dig', debian: 'dnsutils', alpine: 'bind-tools')

Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.add('dig')
    end
  end
end
```

Finally, some packages are more complicated to install. In such cases, define a Ruby class that responds to `install_on_debian` and `install_on_alpine`, and register it with Kuby.

```ruby
class WatchmanPackage < Kuby::Docker::Packages::Package
  def install_on_debian(dockerfile)
    dockerfile.run(<<~END)
      git clone --no-checkout https://github.com/facebook/watchman.git \
        && cd watchman \
        && git checkout v4.7.0 \
        && ./autogen.sh \
        && ./configure \
        && make && make install
    END
  end

  def install_on_alpine(dockerfile)
    # alpine-specific statements
  end
end

Kuby.register_package('watchman', WatchmanPackage)

Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.add('watchman')
    end
  end
end
```

## Custom Build Phases

Kuby builds Docker images in 7 build phases:

1. **Setup phase**: Defines the Docker base image (eg. ruby:2.6.3, ruby:2.6.3-alpine, etc), sets the working directory, and defines the `KUBY_ENV` and `RAILS_ENV` environment variables.
1. **Package phase**: Installs packages via the operating system's package manager, eg. `apt-get`, `apk`, `yum`, etc. Popular packages include things like database drivers (eg. libmysqldev, sqlite3-dev), and image processing libraries (eg. imagemagick, graphicsmagick).
1. **Bundler phase**: Runs `bundle install`, which installs all the Ruby dependencies listed in your app's Gemfile.
1. **Yarn phase**: Runs `yarn install`, which installs all the JavaScript dependencies listed in your app's package.json.
1. **Copy phase**: Copies your app's source code into the image.
1. **Assets phase**: Compiles assets managed by both the asset pipeline and webpacker.
1. **Webserver phase**: Instructs the Docker image to use a webserver to run your app. Currently only the Rails default, [Puma](https://github.com/puma/puma), is supported (including puma in your Gemfile is all you need to do - no other configuration is necessary).

Phases are just Ruby classes that respond to the `apply_to(dockerfile)` method. It's possible to define your own custom phases and insert them into the build process. To do so, create a Ruby class and define the appropriate method. Then, insert your new phase. For example, let's define a phase that writes a file into the image that contains the current git commit ID (it can be handy to know which version of your code your image contains). We assume the current git commit is passed as a Docker build argument, since it won't be available to Docker otherwise (in other words, the .git folder won't and shouldn't be copied into the image).

```ruby
class GitCommitPhase
  def apply_to(dockerfile)
    dockerfile.run('echo $GIT_COMMIT > GIT_COMMIT')
  end
end

Kuby.define('my-app') do
  environment(:production) do
    docker do
      insert :git_commit_phase, GitCommitPhase.new, after: :copy_phase
    end
  end
end
```

`Kuby::Docker::Dockerfile` objects respond to the following methods, which are mapped 1:1 to [Dockerfile instructions](https://docs.docker.com/engine/reference/builder/#format):

1. `from(image_url, as: nil)`
1. `workdir(path)`
1. `env(key, value)`
1. `run(command)`
1. `copy(source, dest, from: nil)`
1. `expose(port)`
1. `cmd(command)`

## Docker build options

You can also provide arbitrary options to the `docker build` command:

```bash
bundle exec kuby build -- [options]
```

For example, you can specify a [custom build target](https://docs.docker.com/engine/reference/commandline/build/#custom-build-outputs):

```bash
bundle exec kuby build -- --output type=tar,dest=out.tar
```
