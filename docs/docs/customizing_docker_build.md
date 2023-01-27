---
id: customizing-docker-build
title: Customizing the Docker Build
sidebar_label: Customizing the Docker Build
slug: /customizing-docker-build
---

We've already seen the standard way to configure Kuby's Docker component (i.e. the `docker do ... end` section), but there's a lot more you can do.

* `app_root String`: Set your application's root directory. This is useful if the app lives in a separate folder, eg. is a demo app for a gem, etc.

All the other Docker build options are described in the sections below.

## Installing Additional Packages

Kuby officially supports the Debian and Alpine distros of Linux for Docker images.

Let's install imagemagick as an example. First, we'll need to register the imagemagick package with Kuby. It just so happens both the Debian and Alpine Linux distros use the same name for their imagemagick package, meaning we can define using just its name.

Next, we tell Kuby to install imagemagick in the `docker` section of our Kuby config:

```ruby
Kuby.register_package(:imagemagick)

Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.add(:imagemagick)
    end
  end
end
```

If the package we want to install has a different name under each of the Linux distros, register it using a hash instead. Let's say we want to install the `dig` command-line utility. In Debian, we'd need to install the `dnsutils` package, but in Alpine we'd need `bind-tools`.

```ruby
Kuby.register_package(:dig, debian: 'dnsutils', alpine: 'bind-tools')

Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.add(:dig)
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

Kuby.register_package(:watchman, WatchmanPackage)

Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.add(:watchman)
    end
  end
end
```

## Selecting a Different Package Version

Some Kuby packages like Yarn and NodeJS support installing specific versions. For example, to install a specific version of NodeJS for your app, first remove the `:nodejs` package and then add it back again using the version you want:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    docker do
      package_phase.remove(:nodejs)
      package_phase.add(:nodejs, '18.10.0')
    end
  end
end
```

## Build Phases

Kuby builds Docker images in 8 build phases. The options available in the various phases are documented below.

### Setup Phase

The setup phase defines the Docker base image (eg. ruby:2.6.3, ruby:2.6.3-alpine, etc), sets the working directory, and defines the `KUBY_ENV` and `RAILS_ENV` environment variables.

* `setup_phase.base_image = String`: Sets the Docker base image on top of which your application's image will be built. Defaults to the official Ruby image for the version of Ruby currently running the `kuby` command.
* `setup_phase.working_dir = String`: Sets the working directory for the Docker image's filesystem. Application code will be copied into this directory and commands like `bundle install` executed within it. Defaults to /usr/src/app.
* `setup_phase.rails_env = String`: Sets `RAILS_ENV`. Defaults to the current Kuby env, which is either the value passed to the Kuby CLI tool via the `-e` flag (eg. `kuby -e production ...`), or the value of the `KUBY_ENV` environment variable.

### Package Phase

The package phase installs packages via the operating system's package manager, eg. `apt-get`, `apk`, `yum`, etc. Popular packages include things like database drivers (eg. postgresql-client, sqlite3-dev), and image processing libraries (eg. imagemagick, graphicsmagick).

* `package_phase.add(package_name: Symbol)`: Adds a package by its name. Packages must be registered ahead of time (see above).
* `package_phase.remove(package_name: Symbol)`: Removes a package by its name.

### Bundler Phase

The Bundler phase installs all the Ruby dependencies listed in your app's Gemfile via Bundler.

* `bundler_phase.version = String`: Sets the version of Bundler to use. Defaults to the current version of Bundler being used to run the `kuby` command.
* `bundler_phase.gemfile = String`: Sets the path to the Gemfile.
* `bundler_phase.without = Array[String]`: Sets the array of Bundler groups to be ignored during installation.
* `bundler_phase.executable = String`: Sets the path to the Bundler executable. Defaults to `bundle`.
* `bundler_phase.gemfiles(gemfiles: Array[String])`: Specifies additional Gemfiles to be copied into the Docker image before installation. Useful if your main Gemfile references other Gemfiles, eg. via the [`eval_gemfile` method](https://medium.com/alliants-blog/modular-composable-gemfiles-5545c83b5319).

### Yarn Phase

The Yarn phase installs all the JavaScript dependencies listed in your app's package.json via Yarn.

### Copy Phase

The copy phase copies your app's source code into the Docker image.

* `copy_phase << String`: Adds an additional path to copy into the image. Defaults to the current directory (eg: ./)

### App Phase

The app phase allows setting environment variables. These variables will be available to any commands run afterwards in the `docker build` process, but will also be accessible to your application via Ruby's `ENV` hash.

* `app_phase.env(key: String, value: String)`: Adds an environment variable.

### Assets Phase

The assets phase compiles static assets managed by both the asset pipeline and Webpacker.

### Webserver Phase

The webserver phase instructs the Docker image to use a webserver to run your app. Currently only the Rails default, [Puma](https://github.com/puma/puma), is supported (including puma in your Gemfile is all you need to do - no other configuration is necessary).

* `webserver_phase.port = Integer`: Sets the port the webserver should listen on.
* `webserver_phase.workers = Integer`: Sets the number of webserver workers to spawn. Defaults to 4.
* `webserver_phase.webserver = Symbol`: Sets the webserver to use. Must be `:puma`. Additional webservers may be supported in the future if there is demand. The only reason to set this field manually is if Kuby can't detect Puma in your Gemfile for some reason.

## Creating A Custom Build Phase

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
1. `arg(arg)` (`arg` is a string of the form `"KEY='value'"`)
1. `run(command)`
1. `copy(source, dest, from: nil)`
1. `expose(port)`
1. `cmd(command)`

Custom build phases can also be inserted inline, without the need to define a class:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    docker do
      insert :git_commit_phase, after: :copy_phase do |dockerfile|
        dockerfile.run('echo $GIT_COMMIT > GIT_COMMIT')
      end
    end
  end
end
```

## Removing Build Phases

Build phases can be removed entirely. For example, if your app is API-only and doesn't have any static assets, then you may want to remove the asset compilation phase entirely:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    docker do
      delete :assets_phase
    end
  end
end
```

## Build Options

It is possible to pass additional build args to `kuby build` via the `-a` (`--arg`) flag. For example, here's how to pass a build arg containing the current Git commit SHA:

```bash
bundle exec kuby build -a SOURCE_COMMIT=$(git rev-parse HEAD)
```

**NOTE:** The example above assumes the `SOURCE_COMMIT` build arg has been added via a custom build phase. To be able to access the value of the arg from the Rails app, it must also be exposed as an environment variable. To accomplish both goals, try something like this:

```ruby
insert :git_commit_arg, after: :setup_phase do |dockerfile|
  dockerfile.arg('SOURCE_COMMIT')
  dockerfile.env('SOURCE_COMMIT', '$SOURCE_COMMIT')
end
```

### Building Specific Images

By default, `kuby build` builds all the registered Docker images. Sometimes it's useful to build a specific one instead. To do so, pass the `--only` option:

```bash
bundle exec kuby build --only app  # only build the app image
```

The value for the `--only` option is an image identifier. A list of all registered images and their identifiers can be obtained via the `kuby images` command.

A similar option is available for the `push` and `dockerfiles` commands, e.g., `kuby push --only app`.

### Arbitrary `docker build` Options

It is also possible to pass arbitrary options to the `docker build` command:

```bash
bundle exec kuby build -- [options]
```

For example, to specify a [custom build target](https://docs.docker.com/engine/reference/commandline/build/#custom-build-outputs), try this:

```bash
bundle exec kuby build -- --output type=tar,dest=out.tar
```

The options given after the `--` will be appended verbatim to the `docker build` command.
