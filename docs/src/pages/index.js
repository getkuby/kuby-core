import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
import SyntaxHighlighter from 'react-syntax-highlighter';
import { vs, ocean } from 'react-syntax-highlighter/dist/esm/styles/hljs';

function Home() {
  const context = useDocusaurusContext();
  const {siteConfig = {}} = context;
  return (
    <Layout
      title={`Hello from ${siteConfig.title}`}
      description={siteConfig.tagline}>
      <header className={clsx('hero hero--primary', styles.heroBanner)}>
        <div className="container">
          <div className="row">
            <div className="col col--7">
              <img className={styles.heroMiniLogo} src={useBaseUrl('/img/kuby-logotype-inverted.svg')}/>
              <p className={clsx('hero__title', styles.heroTitle)}>Deploy Your Rails App the Easy Way</p>
              <p className={clsx('hero__subtitle', styles.heroSubtitle)}>Kuby is a convention-over-configuration approach to deploying Rails apps. It makes the power of Docker and Kubernetes accessible to the average Rails developer without requiring a devops black belt.</p>
              <div className={styles.buttons}>
                <Link
                  className={clsx(
                    'button button--secondary button--lg',
                    styles.getStarted,
                  )}
                  to={useBaseUrl('docs/')}>
                  Get Started
                </Link>
                <div className={clsx(styles.github, 'button--lg')}>
                </div>
              </div>
            </div>
            <div className={clsx("col col--5", styles.heroDemo)}>
            </div>
          </div>
        </div>
      </header>
      <header className={clsx('hero hero--primary', styles.heroSubBanner)}>
        <div className="container">
          <div className="row">
            <div className="col col--4">
              <h3>
                Puts You on the Cutting Edge
              </h3>
              <p>
                Kuby brings the power of Docker and Kubernetes to Rails developers. Easily leverage the plethora of infrastructure tools in the Kubernetes ecosystem in your app.
              </p>
            </div>
            <div className="col col--4">
              <h3>
                Compatible with Cloud Providers
              </h3>
              <p>
                Kuby is compatible with all your favorite cloud providers, including DigitalOcean, Linode, AWS EKS, and Azure. Switch between cloud providers with a single line of code.
              </p>
            </div>
            <div className="col col--4">
              <h3>
                Open-Source
              </h3>
              <p>
                Kuby is 100% open-source and MIT licensed. All contributions welcome!
                <a href="https://github.com/getkuby/kuby-core/releases" className={styles.heroVersion}>
                  <img alt="Gem" src="https://img.shields.io/gem/v/kuby-core?color=%238c0000&label=latest%20version&style=for-the-badge"/>
                </a>
              </p>
            </div>
          </div>
        </div>
      </header>
      <main>
        <section className={clsx('hero hero--light', styles.featureWrapperOdd)}>
          <div className="container">
            <div className="row">
              <div className={clsx('col col--6')}>
                <SyntaxHighlighter language="ruby" style={vs} customStyle={{background: undefined}}>
                  {`
Kuby.define('my-app') do
  environment(:production) do
    docker do
      credentials do
        username ENV['DOCKER_USERNAME']
        password ENV['DOCKER_PASSWORD']
        email ENV['DOCKER_EMAIL']
      end

      image_url 'registry.gitlab.com/me/my-app'
    end

    kubernetes do
      provider :digitalocean do
        access_token ENV['DIGITALOCEAN_ACCESS_TOKEN']
        cluster_id 'my-cluster-id'
      end

      add_plugin :rails_app do
        hostname 'mywebsite.com'

        database do
          user ENV[:DB_USER]
          password ENV[:DB_PASSWORD]
        end
      end
    end
  end
end
                  `}
                </SyntaxHighlighter>
              </div>
              <div className={clsx('col col--6')}>
                <h3>Minimal Configuration</h3>
                <p>
                  This is all you need to deploy your Rails app to your favorite cloud provider. Kuby's convention-over-configuration approach means it uses smart defaults to deploy your app in a standard way. There isn't any complicated documentation to read, and aside from Docker, no additional tools to install.
                </p>
                <h3>Powerful Plugin System</h3>
                <p>
                  Kuby features a plugin system that can make adding features like background jobs really easy. For example, add <a href="https://github.com/mperham/sidekiq">Sidekiq</a> integration with a single <code>add_plugin :sidekiq</code> statement. Kuby comes with a bunch of plugins out-of-the-box, with others installable as ruby gems.
                </p>
                <h3>Database Support</h3>
                <p>
                  Kuby automatically stands up a database for your app based on the contents of your database.yml. Just provide the database credentials and Kuby will do the rest, including automatically connecting to the right host.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className={styles.featureWrapperEven}>
          <div className="container container--primary-dark">
            <div className={clsx('row', styles.feature)}>
              <div className={clsx('col col--6')}>
                <h3>Deploy with a Single Command</h3>
                <p>
                  Deployment can be done easily by running <code>bundle exec kuby -e production deploy</code>. Running this command will deploy the most recently created Docker image for your app to your Kubernetes cluster.
                </p>
                <p>
                  The <code>kuby</code> executable comes with a number of useful commands for administering your Kubernetes cluster. It's essentially a bunch of convenient sugar on top of <code>kubectl</code>, Kubernetes' command-line interface. Know your way around <code>kubectl</code>? No problem. <code>kuby</code> can run arbitrary <code>kubectl</code> commands too.
                </p>
              </div>
              <div className={clsx('col col--6', styles.featureImage)}>
                <img src={useBaseUrl('img/home/deploy.gif')} alt="Deploy animation" />
              </div>
            </div>
          </div>
        </section>

        <section className={styles.featureWrapperOdd}>
          <div className="container">
            <div className={clsx('row', styles.feature)}>
              <div className={clsx('col col--6', styles.featureImage)}>
                <img src={useBaseUrl('img/home/lets-encrypt-logo.svg')} alt="Let's Encrypt logo" />
              </div>
              <div className={clsx('col col--6')}>
                <h3>Automated TLS Certificates</h3>
                <p>
                  Kuby uses <a href="https://letsencrypt.org/">Let's Encrypt</a> to automatically generate and install TLS certificates for your Rails app. Certificates are free and automatically rotated, so you can be sure your app stays secure.
                </p>
                <p>
                  TLS certificate integration is a good example of a Kuby plugin. The <a href="https://github.com/getkuby/kuby-cert-manager">cert-manager plugin</a> leverages the Kubernetes native <a href="https://github.com/jetstack/cert-manager">cert-manager operator</a> and makes it available inside your cluster with no additional configuration.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className={styles.featureWrapperEven}>
          <div className="container container--primary-dark">
            <div className={clsx('row', styles.feature)}>
              <div className={clsx('col col--6')}>
                <h3>Static Asset Server</h3>
                <p>
                  Kuby automatically stands up a separate server for your static assets, freeing up your Rails app to serve requests. Kuby uses <a href="https://www.nginx.com/">Nginx</a>, a popular webserver, that's fast and efficient.
                </p>
                <p>
                  Asset compilation and static asset server setup happens transparently during the Docker build and Kubernetes deploy without any additional configuration.
                </p>
              </div>
              <div className={clsx('col col--6', styles.featureImage)}>
                <img src={useBaseUrl('img/home/static-assets.svg')} alt="Static assets" />
              </div>
            </div>
          </div>
        </section>
      </main>
      <header className={clsx('hero hero--primary', styles.heroBanner)}>
        <div className="container">
          <div className="row">
            <div className="col col--9">
              <p className={clsx('hero__title', styles.heroTitle)}>
                Have some spare time?
              </p>
              <p className="hero__subtitle">
                Kuby is under active development. We need Rails developers to try it out and tell us what breaks. Give it a spin and file an issue!
              </p>
              <div className={styles.buttons}>
                <Link
                  className={clsx(
                    'button button--secondary button--lg',
                    styles.getStarted,
                  )}
                  to={useBaseUrl('docs/')}>
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        </div>
      </header>
    </Layout>
  );
}

export default Home;
