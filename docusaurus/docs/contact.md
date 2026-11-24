---
title: Contact and support
description: Where to ask for help with the vantage_agents role, report a bug, or report a vulnerability
---

## Report a bug or ask for a feature

Open an issue at
[github.com/vantagecompute/ansible-role-vantage_agents/issues](https://github.com/vantagecompute/ansible-role-vantage_agents/issues).

Include:

1. What you expected and what happened.
2. The role version (`ansible-galaxy role list | grep vantage_agents`) and your Ansible version
   (`ansible --version`).
3. The name of the task that failed and its message.
4. The contents of `/etc/vantage/artifacts.lock` on the node.
5. The relevant log, for example `sudo journalctl -u vref-agent -n 50 --no-pager`.

Remove secrets first. The `env` files under `/etc/vantage` hold the client secret and the LDAP
bind password, so do not paste them.

## Report a vulnerability

Email security@vantagecompute.ai. Do not open a public issue.

## Commercial support

For supported deployments of Vantage Compute, write to support@vantagecompute.ai or visit
[vantagecompute.ai](https://vantagecompute.ai).

## Contribute

See [Contributing](./contributing.md).
