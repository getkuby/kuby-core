module.exports = {
  title: 'Kuby',
  tagline: 'Deploy Your Rails App the Easy Way',
  url: 'https://getkuby.io',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  favicon: 'img/favicon.ico',
  organizationName: 'getkuby',
  projectName: 'kuby-core',
  themeConfig: {
    navbar: {
      title: 'Kuby',
      logo: {
        alt: 'Kuby Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          to: 'docs/',
          activeBasePath: 'docs',
          label: 'Docs',
          position: 'left',
        },
        {
          href: 'https://github.com/getkuby/kuby-core',
          label: 'GitHub',
          position: 'left',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Quick Start Guide',
              to: 'docs/',
            },
            {
              label: 'Why Docker and Kubernetes?',
              to: 'docs/why',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/getkuby',
            },
            {
              label: 'Twitter',
              href: 'https://twitter.com/camertron',
            },
          ],
        }
      ],
      copyright: `Copyright © ${new Date().getFullYear()} @camertron. Built with Docusaurus.`,
    },
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true
    },
    prism: {
      additionalLanguages: ['ruby'],
      theme: require('prism-react-renderer/themes/nightOwl'),
    }
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          editUrl:
            'https://github.com/getkuby/kuby-core/edit/master/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
};
