---
title: Usage
description: Apply the vantage_agents role, pin versions, upgrade, and leave a component out
---

## A complete play

The role must run as root, so set `become: true`.

```yaml
- hosts: slurm_head
  become: true
  vars:
    vantage_agents_client_id: my-cluster
    vantage_agents_client_secret: "{{ vault_vantage_client_secret }}"
    vantage_agents_oidc_base_url: https://auth.vantagecompute.ai
    vantage_agents_ldap_url: ldaps://ldap.vantagecompute.ai
    vantage_agents_ldap_organization_id: "{{ vault_vantage_org_id }}"
    vantage_agents_ldap_bind_password: "{{ vault_vantage_ldap_password }}"
    vantage_agents_vref_api_url: https://apis.vantagecompute.ai
    vantage_agents_api_base_url: https://apis.vantagecompute.ai
    vantage_agents_reconciler_version: "X.Y.Z"
    vantage_agents_vref_agent_version: "X.Y.Z"
    vantage_agents_presence_agent_version: "X.Y.Z"
  roles:
    - vantagecompute.vantage_agents
```

```bash
ansible-playbook -i inventory site.yml --ask-vault-pass
```

Every variable is described in [Variables](./variables.md).

:::warning The vref-api URL has no /vref path

Set `vantage_agents_vref_api_url` to the base URL, such as `https://apis.vantagecompute.ai`.
vref-agent adds `/vref` to every route it calls. A value that already ends in `/vref` makes the
agent ask for `/vref/vref/agent/sync`, which does not exist, and `vref-agent.service` fails on
every run.

:::

## Keep the secrets in ansible-vault

Two inputs are secrets: `vantage_agents_client_secret` and `vantage_agents_ldap_bind_password`.
Put them in a vault file and refer to them from the play, as above:

```bash
ansible-vault create group_vars/slurm_head/vault.yml
```

```yaml
vault_vantage_client_secret: "..."
vault_vantage_ldap_password: "..."
vault_vantage_org_id: "..."
```

## Pin the versions

Each binary's version defaults to `latest`, which can change between two runs. In production, set
all three version variables to exact releases.

Whatever the version, the role resolves it to a checksum on every run and reinstalls a binary only
when its checksum differs from the one in `/usr/bin`.

## Upgrade

Change a version variable and run the play again. The role downloads the new build, runs its
`systemd-setup`, and restarts the service.

## Run it again

A second run with the same inputs changes nothing. It is safe to apply the role on a schedule.

## Leave a component out

`vref-agent` and the presence agent carry Ansible tags of their own:

| Tag | Component |
|---|---|
| `vref_agent` | `vref-agent`, its `vrefagent` Slurm user and its token timer |
| `presence_agent` | `cluster-presence-agent` |

```bash
ansible-playbook -i inventory site.yml --skip-tags vref_agent
```

The reconciler has no tag and is always installed. A cluster with no presence agent shows as Not
Connected in Vantage.

## Check the result

On the node:

```bash
systemctl status slurm-accounts-reconciler
systemctl list-timers vref-agent.timer cluster-presence-agent.timer vref-agent-slurm-token.timer
cat /etc/vantage/artifacts.lock
```

`/etc/vantage/artifacts.lock` has one line per installed binary: its name, the version you asked
for, and its sha256.
