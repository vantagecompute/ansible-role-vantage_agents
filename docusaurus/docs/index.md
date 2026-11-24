---
title: "vantage_agents: the Vantage agents on a Slurm node"
sidebar_label: Overview
description: An Ansible role that installs the Vantage agents on a Slurm node and connects it to a Vantage Compute cluster
slug: /
---

`vantage_agents` is an Ansible role that installs the Vantage Compute agents on a node that
already runs Slurm, and connects that node to a Vantage cluster.

It installs three programs, in this order:

| Program | What it does | How it runs |
|---|---|---|
| `slurm-accounts-reconciler` | Keeps Slurm users and accounts in step with the LDAP directory of your Vantage organization | A systemd service |
| `vref-agent` | Watches job state on the cluster and reports it to vref-api. It makes only outbound calls and holds no database credential | A systemd timer, every 10 seconds |
| `cluster-presence-agent` | Reports once a minute that the cluster is alive, which is what makes it show as Connected in Vantage | A systemd timer, every 60 seconds |

The presence agent is installed last, so Vantage shows the cluster as Connected only once
everything else is in place.

## What the role does not do

- It does not install Slurm, MariaDB, InfluxDB or SSSD. The node must already run Slurm with
  slurmrestd and a JWT signing key at `/etc/slurm/jwt_hs256.key`, as the Vantage image does. The
  role checks this first and stops with a clear message when something is missing.
- It does not install the tunnel client or the auth proxy. That is the
  [vantage_tunnel](https://github.com/vantagecompute/ansible-role-vantage_tunnel) role.
- It does not edit `slurm.conf`. See [the slurmctld hook](./architecture.md#the-slurmctld-hook).

## Quick start

Install the role from Ansible Galaxy:

```bash
ansible-galaxy role install vantagecompute.vantage_agents
```

Apply it to a Slurm node, with the secrets in `ansible-vault`:

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
  roles:
    - vantagecompute.vantage_agents
```

Read [Installation](./installation.md) for what the node needs first, and [Usage](./usage.md) for
pinning versions, upgrading and leaving a component out.

## Who applies this role

The Vantage Compute `v8x` command-line tool applies this role, together with `vantage_tunnel`,
when it deploys the `slurm-single-qemu` application. You can apply the same role to your own
nodes.

## Terms

- **slurmrestd** is Slurm's REST API service. The agents talk to Slurm through it.
- **Keycloak and OIDC**: Keycloak is the sign-in service Vantage uses, and OIDC is the protocol it
  speaks. The cluster signs in with a client ID and secret and receives a short-lived token.
- **JWT signing key**: the key Slurm uses to sign and check the login tokens it hands out.
- **LDAP** is the user directory of your organization. The reconciler copies its users and groups
  into Slurm accounts.
- **Accounting operator**: a Slurm user allowed to see all jobs in the accounting database.
  `PrivateData=jobs` is the Slurm setting that hides jobs from other users.
- **systemd timer and path unit**: systemd features that start a service on a schedule (timer) or
  when a file changes (path unit).
- **systemd-setup**: a command each Vantage binary has that installs itself as a systemd service
  (its own user, directories and unit file).
- **ansible-vault**: Ansible's tool for keeping secrets encrypted in a file. `no_log` is the task
  setting that keeps a secret out of Ansible's output.
- **Artifact CDN**: the Vantage download service the binaries come from.
