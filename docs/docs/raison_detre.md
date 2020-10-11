---
id: raison-detre
title: Raison d'Etre
sidebar_label: Raison d'Etre
slug: /raison-detre
---

In other words, "reason for being."

One of Rails' most notorious mantras is "convention over configuration," i.e. sane defaults that limit the cognitive overhead of application development. Rails has survived for as long as it has precisely because it makes so many decisions for you, especially compared to other web application frameworks. It's easy to learn and easy to build with. The development experience is fantastic... right up until the point you want to deploy your app to production. It's at that point that the hand-holding stops. Like the Roadrunner, Rails stops right before the cliff and lets you, Wile E. Coyote, sail over the edge.

![Wile E. Coytote](/img/docs/coyote.jpg)

### Community Discourse

In his appearance on the Ruby Rogues podcast, [episode 403](https://devchat.tv/ruby-rogues/rr-403-rails-needs-active-deployment-with-stefan-wintermeyer/), [Stefan Wintermeyer](https://twitter.com/wintermeyer) described how he sees the current Rails deployment story:

> "In my experience, deployment is one of the major problems of normal Rails users. It is a big pain to set up a deployment system for a Rails application, and I don't see anything out there that makes it easier. [...] I believe that we lose quite a lot of companies and new developers on this step. Because everything else [is] so much easier with Rails. But that last step - and it's a super important step - is still super complicated."

In the 2020 [Rails Community Survey](https://rails-hosting.com/2020/), participants were asked the question, "What are a few things you'd like to see happen in the Ruby on Rails community?" One of the common answers was "A more focused/standardized container-based approach for deploying Rails applications."

### Kuby is Active Deployment

Kuby was designed to serve the same audience as Rails itself, and should be thought of as residing at the same level as active record, active storage, etc. Active record is designed to abstract away the complexities of database communication, and Kuby is designed to do the same abstracting for deployment. Both come, as DHH is fond of saying, with batteries included.

### Who Should Use Kuby?

Kuby is meant for all types of apps, but there are certainly some types that will benefit from it more than others. You're probably better off using a free Heroku dyno for a super small app that doesn't see a lot of traffic and that only manages a few hundred (or less) database rows. It's not that Kuby is a bad choice for these types of apps, it's just that you're likely to spend less money and less brainpower getting Heroku set up. It's pretty hard to get simpler than `git push heroku master`. Heroku starts to get expensive when you need more resources though, and I've found that, generally speaking, a managed Kubernetes cluster with a single node deployed with Kuby is more cost-effective than the equivalent Heroku paid tier setup.

Kuby also might not be the right choice for very large, highly customized apps that have deviated significantly from Rails conventions. I'm sure you could get Kuby to work for such apps, but it would likely mean customizing Kuby to a large degree. To do so, you'd probably have to have a deeper understanding of how Docker, Kubernetes, and Kuby work.
