import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// Curated by hand, so a new page appears only when it is added here.
const sidebars: SidebarsConfig = {
  docsSidebar: [
    'index',
    {
      type: 'category',
      label: 'Getting started',
      items: ['installation', 'usage'],
    },
    {
      type: 'category',
      label: 'Reference',
      items: ['variables', 'architecture', 'security'],
    },
    {
      type: 'category',
      label: 'Support',
      items: ['troubleshooting', 'contact', 'contributing'],
    },
  ],
};

export default sidebars;
