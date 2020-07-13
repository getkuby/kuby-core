## Kuby

Deploy your Rails app the easy way.

## What is Kuby?

At its core, Kuby is a set of tools and smart defaults that encapsulate and codify years of established best-practices around deploying webapps, reducing the amount of time required to take your Rails project from an app that runs on your computer to an app that runs on the Internet.

Under the hood, Kuby leverages the power of Docker and Kubernetes. It tries to make these technologies accessible to the average Rails dev without requiring a devops black belt.

## Raison d'etre

One of Rails' most notorious mantras is "convention over configuration," i.e. sane defaults that limit the cognitive overhead of application development. Rails has survived for as long as it has precisely because it makes so many decisions for you, especially compared to other web application frameworks. It's easy to learn and easy to build with. The development experience is fantastic... right up until the point you want to deploy your app to production. It's at that point that the hand-holding stops. Like the Roadrunner, Rails stops right before the cliff and lets you, Wile E. Coyote, sail over the edge.

![Wile E. Coytote](coyote.jpg)

Perhaps [Stefan Wintermeyer](https://twitter.com/wintermeyer) said it best during his appearance on the Ruby Rogues podcast, [episode 403](https://devchat.tv/ruby-rogues/rr-403-rails-needs-active-deployment-with-stefan-wintermeyer/):

> "In my experience, deployment is one of the major problems of normal Rails users. It is a big pain to set up a deployment system for a Rails application, and I don't see anything out there that makes it easier. [...] I believe that we lose quite a lot of companies and new developers on this step. Because everything else [is] so much easier with Rails. But that last step - and it's a super important step - is still super complicated."

## Why Docker and Kubernetes?

So, why bet the farm on Docker and Kubernetes?

### Why Docker

When Docker came on the scene in 2013 it was seen as a game-changer. Applications that used to be deployed onto hand-provisioned servers can now be bundled up into neat little packages and transferred between computers in their entirety. Since the whole application - dependencies, operating system components, assets, code, etc - can be passed around as a single artifact, Docker images curtail the need for manually provisioned servers and eliminate a whole class of "works on my machine" problems.

### Why Kubernetes

Kubernetes has taken the ops world by storm. It's resilient to failure, portable across a variety of cloud providers, and backed by industry-leading organizations like the CNCF. Kubernetes configuration is portable enough to be used, without modification, on just about any Kubernetes cluster, making migrations not only feasible, but easy. Many cloud providers like Google GCP, Amazon AWS, Microsoft Azure, DigitalOcean, and Linode support Kubernetes. Most of these providers will manage the Kubernetes cluster for you, and in some cases will even provide it free of charge (you pay only for the compute resources).

## Getting Started

NOTE: Kuby is designed to work with Rails 5.1 and up.

### Choosing a Provider

The first step in deploying your app is to choose a hosting provider. At the time of this writing, Kuby supports DigitalOcean and Linode, but support for more providers is coming soon. Use your provider's dashboard to spin up a Kubernetes cluster. In most cases, this shouldn't involve more than a few button clicks.

### Using a Container Registry

Kuby uses Docker to package up your application into a Docker _image_. Images are then pushed (i.e. uploaded) to something called a "container registry." Container registries host Docker images so they can be pulled (i.e. downloaded) later.

Although there are a number of container registries available (some free and some paid), consider using the Gitlab registry. Gitlab's registry is free and unlimited. You don't have to host your code on Gitlab to take advantage of the registry, but they're great for that too.

### Integrating Kuby Into Your App

Kuby configuration is done via a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language). There are two main sections, one for Docker and one for Kubernetes. Put the config into a Rails initializer, eg. config/initializers/kuby.rb.

Here's what a complete config looks like:

```ruby
Kuby.define(:production) do
  docker do
    credentials do
      username ENV['DOCKER_USERNAME']
      password ENV['DOCKER_PASSWORD']
      email ENV['DOCKER_EMAIL']
    end

    image_url 'registry.gitlab.com/username/repo'
  end

  kubernetes do
    provider :digitalocean do
      access_token ENV['DIGITALOCEAN_ACCESS_TOKEN']
      cluster_id 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
    end

    add_plugin :rails_app do
      hostname 'mywebsite.com'
    end
  end
end
```

Let's go over this config in detail.

### Deploy Environments

The first line defines the _deploy environment_:

```ruby
Kuby.define(:production)
```

Deploy environments usually closely mirror your Rails environments. For example, you might create a new Rails environment called "staging" or "preprod" that's used to test production changes before they go live. You'll want to create a "staging" Kuby deploy environment as well.

If you're a small shop or hobbyist though, chances are the "production" deploy environment is all you need.

### Configuring Docker

Kuby can automatically "dockerize" your application. You just need to tell it where to push images and provide some credentials:

```ruby
docker do
  credentials do
    username ENV['DOCKER_USERNAME']
    password ENV['DOCKER_PASSWORD']
    email ENV['DOCKER_EMAIL']
  end

  image_url 'registry.gitlab.com/username/repo'
end
```

The username, password, and email fields are used to authenticate with the Docker registry that hosts your images. For Gitlab, you'll need to create a [personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) instead of your password. The `image_url` field is the full URL to your image, including the registry's domain.

In the example above, the username, password, and email are all provided as environment variables. **NEVER** hard-code sensitive information like this in your Kuby config or check it into source control (i.e. git). Consider using a tool like [dotenv](https://github.com/bkeepers/dotenv) to automatically load the variables from a file when your app starts (NOTE: don't check the .env file into git either!)

### Configuring Kubernetes

Now that your app can be packaged up into a Docker image, it's time to use Kubernetes to run it. There are two top-level concerns in the Kubernetes section of your Kuby config: providers and plugins.

#### Providers

Each Kubernetes definition must have a provider configured. Providers correspond to the hosting provider you chose earlier. For example, you'll need to add the `:digitalocean` provider to deploy to a managed DigitalOcean Kubernetes cluster.

```ruby
kubernetes do
  provider :digitalocean do
    access_token ENV['DIGITALOCEAN_ACCESS_TOKEN']
    cluster_id 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
  end
end
```

Kuby providers are distributed as individual rubygems. Add the one you need to your Gemfile, for example:

```ruby
gem 'kuby-digitalocean', '~> 0.1'
```

Providers can have different config options, so make sure you consult the gem's README for the provider you've chosen.

#### Plugins

Nearly all Kuby's functionality is provided via plugins. For example, simply add the `:rails_app` plugin to get your Rails app ready to deploy:

```ruby
add_plugin :rails_app
```

To indicate your app exists behind a particular domain name, specify the `hostname` option:

```ruby
add_plugin :rails_app do
  hostname 'mywebsite.com'
end
```

Configuring DNS to point to your Kubernetes cluster is outside the scope of this README, but all the hosting providers should have tutorials. For example, [here's the one](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) from DigitalOcean.

## Deploying

Now that Kuby is configured and your Kubernetes cluster is ready, it's time to deploy!

1. Build the Docker image

    ```sh
    bundle exec rake kuby:build
    ```
1. Push the Docker image to the container registry

    ```sh
    bundle exec rake kuby:push
    ```
1. Deploy!

    ```sh
    bundle exec rake kuby:deploy
    ```
1. Rejoice

## Checking in on Your App

Great, you've deployed your app! Now what?

Check the status of your deployment by running:

```bash
bundle exec rake kuby:remote:status
```

The obvious way to see if your app is working or not is to try to access it over the Internet. If the deploy succeeded (and `rake status` indicates everything's up and running) but your app is erroring out, chances are something is misconfigured. A good place to look when diagnosing issues is your Rails server log. Run the following rake task to see a live log tail:

```bash
bundle exec rake kuby:remote:logs
```

Establish a shell session by running:

```bash
bundle exec rake kuby:remote:shell
```

Establish a Rails console session by running:

```bash
bundle exec rake kuby:remote:console
```

Establish a database console session by running:

```bash
bundle exec rake kuby:remote:dbconsole
```

## Customizing Kuby

Kuby is designed to be highly customizable. You can customize how Docker images are built by running your own commands and installing your own packages. You can customize the Kubernetes deployment process by modifying resources and adding additional resources of your own. Customization requires a bit more knowledge around how Docker and Kubernetes work, so you may want to invest some time learning more about them before diving in too deep.

### Customizing the Docker Build

We've already seen the standard way to configure Kuby's Docker component (i.e. `docker do ... end` above), but there's a lot more you can do.

#### Installing Additional Packages

Kuby officially supports the Debian and Alpine distros of Linux for Docker images.

Let's install imagemagick as an example. First, we'll need to register the imagemagick package with Kuby. It just so happens both the Debian and Alpine Linux distros use the same name for their imagemagick package, meaning we can define using just its name.

Next, we tell Kuby to install imagemagick in the `docker` section of our Kuby config:

```ruby
Kuby.register_package('imagemagick')

Kuby.define(:production) do
  docker do
    package_phase.add('imagemagick')
  end
end
```

If the package we want to install has a different name under each of the Linux distros, register it using a hash instead. Let's say we want to install the `dig` command-line utility. In Debian, we'd need to install the `dnsutils` package, but in Alpine we'd need `bind-tools`.

```ruby
Kuby.register_package('dig', debian: 'dnsutils', alpine: 'bind-tools')

Kuby.define(:production) do
  docker do
    package_phase.add('dig')
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

Kuby.define(:production) do
  docker do
    package_phase.add('watchman')
  end
end
```

#### Custom Build Phases

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

Kuby.define(:production) do
  docker do
    insert :git_commit_phase, GitCommitPhase.new, after: :copy_phase
  end
end
```

### Customizing the Deploy

In Kubernetes, everything is a resource. Resources generally have a "kind" (eg. "ConfigMap", "Namespace", etc), and a unique name. Kubernetes resources are usually stored as flat .yml or .json files and applied via the Kubernetes CLI, `kubectl` (vocalized as "kube control", or "kube cuttle"), but Kuby does things a little differently. In Kuby, resources are defined in Ruby code using the [KubeDSL gem](https://github.com/getkuby/kube-dsl). Kuby defines around 10 resources for a standard Rails app, which are summarized below.

1. **Namepace**: A Kubernetes namespace inside which all other resources are defined.
1. **ServiceAccount**: An account permitted to make changes inside the namespace.
1. **Service**: Defines an HTTP interface to your app and defines which ports should be exposed.
1. **ConfigMap**: Contains configuration data your app needs to run, usually key/value pairs.
1. **Secret**: Contains app "secrets", i.e. sensitive configuration data like 3rd party API keys, passwords, etc. By default, this only contains the contents of `RAILS_MASTER_KEY`.
1. **Deployment**: Specifies how to deploy your app. Includes configuration for creating and migrating the database, as well as where to get the Docker image and how to safely restart the Rails server without dropping requests.
1. **Ingress**: Defines how connections to your app will be made from the outside world.

To customize these resources, you simply have to know where they're defined. Most of Kuby's resources are exposed publicly and allow for modification. For example, here's how to disable TLS for your Rails app (it's turned on by default):

```ruby
Kuby.define(:production) do
  kubernetes do
    plugin :rails_app do
      tls_enabled false
    end
  end
end
```

## Secrets

## Data Stores

## TLS

## Custom Resources

## Creating your own Plugin

## Running Tests

`bundle exec rspec` should do the trick... or at least it would if there were any tests. Don't worry, it's on my radar.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
