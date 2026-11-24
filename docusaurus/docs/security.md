---
title: Security
description: Which secrets the vantage_agents role handles, where it leaves them, and what its download check does and does not prove
---

## The secrets the role handles

| Secret | Input | Where it ends up on the node |
|---|---|---|
| The cluster's client secret | `vantage_agents_client_secret` | `/etc/vantage/vref-agent/env` and `/etc/vantage/cluster-presence-agent/env` |
| The LDAP bind password | `vantage_agents_ldap_bind_password` | `/etc/vantage/slurm-accounts-reconciler/env` |
| The Slurm JWT signing key | Already on the node at `/etc/slurm/jwt_hs256.key` | A copy at `/etc/vantage/slurm-accounts-reconciler/jwt_hs256.key` |
| The `vrefagent` Slurm token | Minted on the node | `/etc/vantage/vref-agent/slurm.token` |

## File permissions

| File | Owner and mode | Who reads it |
|---|---|---|
| Each `env` file | `root:root`, `0600` | systemd reads it as root before it starts the service as its own user |
| The reconciler's key copy | `root:slurm-accounts-reconciler`, `0640` | The reconciler |
| `slurm.token` | `root:vref-agent`, `0640` | vref-agent |

The token file is written to a temporary file with a restrictive mask and then renamed, so it is
never briefly readable by others or half written.

## Keeping secrets out of Ansible's output

Every task that handles a secret sets `no_log: true`: the token request, the downloads (which send
the token), the settings templates and the key copy. The cost is that a failure in one of those
tasks shows no detail. [Troubleshooting](./troubleshooting.md#a-task-fails-with-its-output-hidden)
explains how to find the cause.

Keep the two secret inputs in `ansible-vault`, not in plain variables files.

## What the download check proves

The role checks each binary against a `.sha256` file from the same CDN, fetched with the same
token. That catches a damaged or incomplete download. It does not protect against a compromised
CDN, which could serve a matching binary and checksum.

## What each agent can reach

| Agent | Calls out to | Access on the node |
|---|---|---|
| `slurm-accounts-reconciler` | The LDAP directory | slurmrestd, with tokens it signs itself using its copy of the JWT key |
| `vref-agent` | vref-api and Keycloak | slurmrestd, as `vrefagent`. It holds no database credential |
| `cluster-presence-agent` | The Vantage API and Keycloak | None |

None of the agents listens for inbound connections.

The reconciler's copy of the JWT signing key lets it mint a Slurm token for any user. Treat the
`slurm-accounts-reconciler` group as you treat access to the key itself.

`vrefagent` needs to see every user's jobs. On a cluster that sets `PrivateData=jobs` in
`slurmdbd.conf`, that means making `vrefagent` an accounting operator.

## Reporting a vulnerability

Email security@vantagecompute.ai. Do not open a public issue.
