import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import {staticDir, getProjectVersion} from '@vantagecompute/docusaurus-theme';

// The version is the nearest git tag, which is also the role's version on
// Ansible Galaxy.
const projectVersion = getProjectVersion();

const config: Config = {
  title: 'vantage_agents',
  tagline: `The Ansible role that installs the Vantage agents on a Slurm node (${projectVersion})`,
  favicon: 'img/favicon.ico',

  url: 'https://docs.vantagecompute.ai',
  // The spoke name. It must match the entry in vantage-docs'
  // .developer-subsites.json and the S3 prefix in deploy-docs.yml.
  baseUrl: '/developer/ansible-vantage-agents/',
  noIndex: true,

  organizationName: 'vantagecompute',
  projectName: 'ansible-role-vantage_agents',
  deploymentBranch: 'main',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  markdown: {
    format: 'detect',
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },
  // The theme renders the navbar and (no) footer itself: this site is a
  // developer spoke, so it gets the developer navbar with the brand mark,
  // the centred title and version, and these two buttons. There is no
  // themeConfig.navbar and no footer below; both belong to the theme.
  themes: [
    '@docusaurus/theme-mermaid',
    [
      '@vantagecompute/docusaurus-theme',
      {
        navbarLinks: [
          {label: 'GitHub', url: 'https://github.com/vantagecompute/ansible-role-vantage_agents'},
          {label: 'Ansible Galaxy', url: 'https://galaxy.ansible.com/ui/standalone/roles/vantagecompute/vantage_agents/'},
        ],
      },
    ],
  ],

  staticDirectories: ['static', staticDir],

  presets: [
    [
      'classic',
      {
        docs: {
          path: './docs',
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/vantagecompute/ansible-role-vantage_agents/tree/main/docusaurus/',
        },
        blog: false,
      },
    ],
  ],
  plugins: [
    [
      'docusaurus-plugin-llms',
      {
        generateLLMsTxt: true,
        generateLLMsFullTxt: true,
        docsDir: 'docs',
        title: 'vantage_agents Ansible role documentation',
        description: 'How to install and configure the Vantage agents with the vantage_agents Ansible role.',
        includeBlog: false,
        excludeImports: true,
        removeDuplicateHeadings: true,
        generateMarkdownFiles: true,
        includeOrder: [],
        includeUnmatchedLast: true,
        pathTransformation: {
          ignorePaths: ['docs'],
        },
      },
    ],
  ],

  customFields: {
    projectVersion: projectVersion,
  },

  themeConfig: {
    codeBlock: {
      showCopyButton: true,
    },
    prism: {
      theme: prismThemes.vsLight,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['shell-session', 'bash', 'yaml', 'json', 'ini'],
    },
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 4,
    },
  },
};

export default config;
