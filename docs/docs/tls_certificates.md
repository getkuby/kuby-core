---
id: tls-certificates
title: TLS Certificates
sidebar_label: TLS Certificates
slug: /tls-certificates
---

Kuby uses [cert-manager](https://github.com/jetstack/cert-manager) to automatically request and install TLS certificates on your behalf. Behind the scenes, cert-manager uses [Let's Encrypt](https://letsencrypt.org/), a non-profit certificate authority trusted by all the major browsers. You don't need an account to use Let's Encrypt, but you do need an email address. By default, Kuby uses the email address you provided as part of your Docker registry credentials. A certificate will be issued for the hostname configured for your Rails app. Note that the certificate request and installation process can sometimes take a few minutes or even a few hours depending on a number of factors. For example, if DNS hasn't propagated fully, Let's Encrypt may not be able to make requests to your app and therefore will not be able to verify you own the domain name. In most cases, you just need to wait.
