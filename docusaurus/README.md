# vantage_agents documentation

The documentation site for the `vantage_agents` Ansible role, built with
[Docusaurus](https://docusaurus.io/) and the Vantage Compute theme. It is published at
`https://docs.vantagecompute.ai/developer/ansible-vantage-agents/` when a version tag is pushed.

Run these from the repository root. They need Node 26 or newer and Yarn.

| Command | What it does |
|---|---|
| `just docs-dev` | Starts a local server that reloads as you edit |
| `just docs-build` | Builds the site into `docusaurus/build`, and fails on a broken link |
| `just docs-serve` | Builds the site and serves the result |
| `just docs-clean` | Removes the build output |

The pages are in `docs/`. A new page appears in the sidebar only when you add it to `sidebars.ts`.

The site name `ansible-vantage-agents` appears in three places that must agree: `baseUrl` in
`docusaurus.config.ts`, the S3 prefix in `.github/workflows/deploy-docs.yml`, and the entry in
`.developer-subsites.json` in the `vantage-docs` repository.
