import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Introduction to Operating Systems',
  tagline: 'Learn to master the Linux 🐧 command line',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://linux-101.wyliodrin.com',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'upb-cs-iso', // Usually your GitHub org/user name.
  projectName: 'upb-cs-iso.github.io', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/upb-cs-iso/upb-cs-iso.github.io/edit/main/',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/ipworkshop-social-card.png',
    navbar: {
      title: 'Introduction to (Linux) Operating Systems',
      logo: {
        alt: 'Tux logo',
        src: 'img/tux.png',
      },
      items: [
        {
          type: 'doc',
          position: 'left',
          label: 'Lectures',
          docId: '/category/lectures'
        },
        {
          type: 'doc',
          position: 'left',
          label: 'Labs',
          docId: '/category/labs'
        },
        {
          href: 'https://github.com/upb-cs-iso/upb-cs-iso.github.io',
          label: 'GitHub',
          position: 'right',
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
              label: 'Lectures',
              to: '/docs/category/lectures',
            },
            {
              label: 'Labs',
              to: '/docs/category/labs',
            }],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Facebook',
              href: 'https://www.facebook.com/uso.acs',
            }
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/upb-cs-iso/',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Wyliodrin and Politehnica Bucharest. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
