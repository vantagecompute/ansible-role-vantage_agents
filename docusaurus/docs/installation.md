---
title: Installation
description: What a node needs before the vantage_agents role runs, and how to install the role from Ansible Galaxy
---

## What you need

On the machine that runs Ansible (the control machine):

- Ansible 2.16 or newer. The role uses only `ansible.builtin` modules, so `ansible-core` is enough.

On the node the role is applied to:

- Ubuntu 26.04 on x86_64. Other platforms are not supported yet, and the role stops on them.
- Slurm, already installed and running, with slurmrestd, `scontrol` at `/usr/bin/scontrol`, and
  the JWT signing key at `/etc/slurm/jwt_hs256.key`.
- The user slurmctld runs as (`slurm` unless you set `vantage_agents_slurm_user`).
- Outbound HTTPS to the artifact CDN, the Keycloak realm, vref-api and the Vantage API.
- A Slurm that lets the `vrefagent` user see every user's jobs: no `PrivateData=jobs` in
  `slurm.conf`, and either none in `slurmdbd.conf` or `vrefagent` as an accounting operator.

From Vantage:

- A cluster and its Keycloak client credentials. The client ID is the cluster ID.
- The LDAP URL, organization ID and bind password of your organization.

## Install the role

From Ansible Galaxy:

```bash
ansible-galaxy role install vantagecompute.vantage_agents
```

To install an exact version, which is what a production deployment should do:

```bash
ansible-galaxy role install vantagecompute.vantage_agents,0.1.0
```

Or name it in a `requirements.yml` beside your playbook:

```yaml
roles:
  - name: vantagecompute.vantage_agents
    version: "0.1.0"
```

```bash
ansible-galaxy role install -r requirements.yml
```

A role version is a git tag of the
[role's repository](https://github.com/vantagecompute/ansible-role-vantage_agents/tags).

## Check the installation

```bash
ansible-galaxy role list | grep vantage_agents
```

Then write a play as shown in [Usage](./usage.md).
