---
title: Variables
description: Every input of the vantage_agents role, with its default and meaning
---

All inputs start with `vantage_agents_`.

## Required

The role stops before changing anything when one of these is empty.

| Variable | Meaning |
|---|---|
| `vantage_agents_client_id` | The cluster's Keycloak client ID, which is the cluster ID |
| `vantage_agents_client_secret` | The client secret. Keep it in `ansible-vault` |
| `vantage_agents_oidc_base_url` | The Keycloak base URL without `/realms/vantage`, for example `https://auth.vantagecompute.ai` |
| `vantage_agents_ldap_url` | The LDAP URL of your organization |
| `vantage_agents_ldap_organization_id` | Your organization ID |
| `vantage_agents_ldap_bind_password` | The LDAP bind password. Keep it in `ansible-vault` |
| `vantage_agents_vref_api_url` | The base URL of vref-api, with no `/vref` path, for example `https://apis.vantagecompute.ai` |
| `vantage_agents_api_base_url` | The base URL of the Vantage API the presence agent reports to, for example `https://apis.vantagecompute.ai` |

## Optional

| Variable | Default | Meaning |
|---|---|---|
| `vantage_agents_artifacts_url` | `https://vantage-artifacts.vantagecompute.ai` | Where the binaries are downloaded from |
| `vantage_agents_reconciler_version` | `latest` | The `slurm-accounts-reconciler` version. Pin it in production |
| `vantage_agents_vref_agent_version` | `latest` | The `vref-agent` version, `0.1.5` or later. Pin it in production |
| `vantage_agents_presence_agent_version` | `latest` | The `cluster-presence-agent` version. Pin it in production |
| `vantage_agents_slurmrestd_url` | `http://127.0.0.1:6820` | The cluster's slurmrestd |
| `vantage_agents_slurm_user` | `slurm` | The user slurmctld runs as. It must exist |
| `vantage_agents_vref_container_engine` | empty | `pyxis` or `apptainer`. Leave it empty when the cluster runs neither |
| `vantage_agents_slurm_token_lifespan` | `604800` | How many seconds a vref-agent Slurm token lives (7 days by default) |
| `vantage_agents_slurm_token_refresh` | `daily` | When the token is re-minted, as a systemd `OnCalendar` value such as `daily` or `*-*-* 03:00:00` |

Keep the lifespan longer than the time between two refreshes, or the agent is left with an expired
token.

## Fixed values

These are constants in the role's `vars/main.yml`, not inputs. They are listed so you know where
to look on a node.

| What | Value |
|---|---|
| Keycloak realm | `/realms/vantage`, added to `vantage_agents_oidc_base_url` |
| Binary architecture | `linux-amd64` |
| Download cache | `/var/cache/vantage-agents` |
| Install record | `/etc/vantage/artifacts.lock` |
| Slurm JWT signing key the role expects | `/etc/slurm/jwt_hs256.key` |
| Reconciler settings | `/etc/vantage/slurm-accounts-reconciler/env` |
| vref-agent settings | `/etc/vantage/vref-agent/env` |
| vref-agent Slurm token | `/etc/vantage/vref-agent/slurm.token` |
| vref-agent Slurm user | `vrefagent` |
| Presence agent settings | `/etc/vantage/cluster-presence-agent/env` |
| Presence report interval | 60 seconds |
| LDAP base DN | `dc=vantagecompute,dc=ai` |
