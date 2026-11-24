---
title: Troubleshooting
description: Failures of the vantage_agents role and of the agents it installs, with the cause and the fix for each
---

## The run stops in the first checks

| Message | Cause and fix |
|---|---|
| `This role supports Ubuntu 26.04 on x86_64 only.` | The node runs something else. Other platforms are not supported yet. |
| `The variable vantage_agents_... is required and is empty.` | Set that variable. See [Variables](./variables.md#required). |
| The task `Check that the Slurm user exists` fails | The user in `vantage_agents_slurm_user` (default `slurm`) does not exist. Set the variable to the user slurmctld runs as. |
| `/etc/slurm/jwt_hs256.key is missing.` or `/usr/bin/scontrol is missing.` | The node does not run Slurm the way the role expects. The role does not install Slurm. Install and configure it first, with JWT authentication. |

## A task fails with its output hidden

Tasks that handle secrets hide their output, so a failure reads
`the output has been hidden due to the fact that 'no_log: true' was specified`. Find the cause from
the task's name:

| Task | Likely cause |
|---|---|
| `Get a Keycloak token for the artifact CDN` | A wrong client ID or secret, a wrong `vantage_agents_oidc_base_url` (it must not include `/realms/vantage`), or no route to Keycloak |
| `Fetch the checksum of ...` | A version that does not exist, a wrong `vantage_agents_artifacts_url`, or no route to the CDN |
| `Download ...` | A dropped connection, or a download that does not match its checksum. Run again |

To see the detail, repeat the request by hand from the node. Do not turn `no_log` off on a shared
machine: the secret would be written to the terminal and to any log of the run.

## vref-agent has no systemd-setup command

The message names the build and says it `has no systemd-setup command`. The artifact CDN served
the older cloud-side agent. Set `vantage_agents_vref_agent_version` to `0.1.5` or later.

## scontrol returned no token

The token script could not mint a Slurm token for `vrefagent`. Check that slurmctld is running and
that Slurm is configured for JWT authentication:

```bash
systemctl status slurmctld
sudo scontrol token username=vrefagent lifespan=60
```

## vref-agent.service fails on every run

Read its log as root. A regular user sees no entries.

```bash
sudo journalctl -u vref-agent -n 20 --no-pager
```

| What you find | Cause and fix |
|---|---|
| A `404` from vref-api | `vantage_agents_vref_api_url` ends in `/vref`. Set it to the base URL, such as `https://apis.vantagecompute.ai`, and run the play again. |
| A `401` or `403` | The client ID or secret is wrong, or the cluster is not known to vref-api. |
| The token file cannot be read, or slurmrestd refuses the token | Run `sudo systemctl start vref-agent-slurm-token.service` and read its log. |
| The service never runs at all | It starts only once `/etc/vantage/vref-agent/env` exists. Run the play again without `--skip-tags vref_agent`. |

Running `/usr/bin/vref-agent run` from a shell prints `missing required settings` for every
setting. That is expected: the settings are in `/etc/vantage/vref-agent/env`, which only systemd
loads.

## The cluster does not show as Connected

```bash
systemctl list-timers cluster-presence-agent.timer
sudo journalctl -u cluster-presence-agent.service -n 20 --no-pager
```

No timer means the role did not reach its last step, or ran with `--skip-tags presence_agent`.
Otherwise check `vantage_agents_api_base_url` and that the node can reach it over HTTPS.

## Slurm accounts do not match the directory

```bash
systemctl status slurm-accounts-reconciler
sudo journalctl -u slurm-accounts-reconciler -n 50 --no-pager
```

Check `vantage_agents_ldap_url`, the organization ID and the bind password, and that the node can
reach the LDAP server.

## Which build is installed

```bash
cat /etc/vantage/artifacts.lock
sha256sum /usr/bin/vref-agent
```

The checksum in the lock file matches the binary in `/usr/bin` after a successful run.
