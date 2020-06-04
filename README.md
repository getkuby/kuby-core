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

## Docker and Kubernetes

Why bet the farm on Docker and Kubernetes?

### Docker

When Docker came on the scene in 2013 it was seen as a game-changer. Applications that used to be deployed onto hand-provisioned servers can now be bundled up into neat little packages and transferred between computers in their entirety. Since the whole application - dependencies, operating system components, assets, code, etc - can be passed around as a single artifact, Docker images eliminate the need for manually provisioned servers and eliminate a whole class of "works on my machine" problems.

### Kubernetes

Kubernetes has taken the ops world by storm. It's resilient to failure, portable across a variety of cloud providers, and backed by industry-leading organizations like the CNCF. Kubernetes configuration is portable enough to be used, without modification, on just about any Kubernetes cluster, making migrations not only feasible, but easy. Many cloud providers like Google GCP, Amazon AWS, Microsoft Azure, DigitalOcean, and Linode support Kubernetes. Most of these providers will even manage the Kubernetes cluster for you, and in some cases will even provide it free of charge (you pay only for the compute resources).

## Getting Started

NOTE: Kuby is designed to work with Rails 5.2 and up.

### Choosing a Provider

The first step in deploying your app is to choose a hosting provider. At the time of this writing, Kuby supports DigitalOcean and Linode, but support for more providers is coming soon. Use your provider's dashboard to spin up a Kubernetes cluster. In most cases, this shouldn't involve more than a few button clicks.

### The Container Registry

Kuby uses Docker to package up your application into a Docker _image_. Images are then pushed (i.e. uploaded) to something called a "container registry." Container registries host Docker images so they can be pulled (i.e. downloaded) later.

Although there are a number of container registries available (some free and some paid), consider using the Gitlab registry. Gitlab's registry is free and unlimited. You don't have to host your code on Gitlab to take advantage of the registry, but they're great for that too.

### Integrating Kuby

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

Deploy environments usually closely mirror your Rails environments. For example, you might create a new Rails environment called "staging" or "preprod" that's used to test production changes before they go live.

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

Configuring DNS to point to your Kubernetes cluster is outside the scope of this README, but all the hosting providers should have tutorials. For example, [here's one](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) from DigitalOcean.

## Deploying

Now that Kuby is configured and your Kubernetes cluster is ready, it's time to deploy!

1. Build the Docker image
    ```sh
    bundle exec rake kuby:build
    ```
1. Push the Docker image to the container registry:
    ```sh
    bundle exec rake kuby:push
    ```
1. Deploy!
    ```sh
    bundle exec rake kuby:deploy
    ```
1. Rejoice

## Running Tests

`bundle exec rspec` should do the trick :)

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
