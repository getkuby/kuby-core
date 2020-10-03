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

Kuby's goal is to provide this missing piece of the Rails development story - a deployment mechanism with sane defaults that works for 90% of use cases. Kuby aims to be "Active Deployment" for Rails.
