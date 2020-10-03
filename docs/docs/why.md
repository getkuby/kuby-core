---
id: why
title: Why Docker and Kubernetes?
sidebar_label: Why Docker and Kubernetes?
slug: /why
---

So, why bet the farm on Docker and Kubernetes?

### Why Docker

When Docker came on the scene in 2013 it was seen as a game-changer. Applications that used to be deployed onto hand-provisioned servers can now be bundled up into neat little packages and transferred between computers in their entirety. Since the whole application - dependencies, operating system components, assets, code, etc - can be passed around as a single artifact, Docker images curtail the need for manually provisioned servers and eliminate a whole class of "works on my machine" problems.

### Why Kubernetes

Kubernetes has taken the ops world by storm. It's resilient to failure, portable across a variety of cloud providers, and backed by industry-leading organizations like the CNCF. Kubernetes configuration is portable enough to be used, without modification, on just about any Kubernetes cluster, making migrations not only feasible, but easy. Many cloud providers like Google GCP, Amazon AWS, Microsoft Azure, DigitalOcean, and Linode support Kubernetes. Most of these providers will manage the Kubernetes cluster for you, and in some cases will even provide it free of charge (you pay only for the compute resources).

"Sure," I hear you saying, "but Kubernetes is really complicated, and I just have a simple web app! Surely there's a simpler way?" You're right, of course. Kubernetes was originally designed by Google to manage their infrastructure, and you probably don't have Google-sized problems to worry about. That said, I'm a firm believer in Kubernetes' viability for applications of all sizes and types. Kubernetes is very much the "batteries included" orchestration layer like Rails is for web applications. It is fast becoming the lingua franca of orchestration, and there's no reason large and small web apps alike can't make use of its awesome feature set.
