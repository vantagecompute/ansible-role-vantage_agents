# vantage_agents

An Ansible role that installs the Vantage agents on a Slurm node and connects it to a Vantage cluster:

- **cluster-presence-agent** reports once a minute that this cluster is alive, which is what makes it show as Connected in Vantage. It is installed last.
- **slurm-accounts-reconciler** keeps Slurm users and accounts in step with the LDAP directory of your Vantage organization.
- **vref-agent** watches job state on the cluster and reports it to vref-api. It runs as a systemd timer (every 10 seconds), makes only outbound calls, and holds no database credential.

The Vantage Compute `v8x` tool is meant to apply this role, together with `vantage_tunnel`, when it deploys the Slurm single-node demo. You can apply the same role to your own nodes.

## What this role does not do

It does not install Slurm, MariaDB, InfluxDB or SSSD. The node must already run Slurm with slurmrestd and a JWT signing key at `/etc/slurm/jwt_hs256.key`, as the Vantage image does. The role checks this first and stops with a clear message when something is missing. It does not install the tunnel or the auth proxy; that is the `vantage_tunnel` role.

## Requirements

- Ubuntu 26.04 on x86_64. Other platforms are not supported yet.
- Ansible 2.16 or newer on the control machine, and `become: true` on the play.
- A Vantage cluster and its Keycloak client credentials. The client ID is the cluster ID.
- Outbound HTTPS from the node to the artifact CDN, the Keycloak realm and vref-api.
- A Slurm that lets the `vrefagent` user see every user's jobs: no `PrivateData=jobs` in `slurm.conf`, and either none in `slurmdbd.conf` or `vrefagent` as an accounting operator.

## Terms

- **slurmrestd** is Slurm's REST API service. The agents talk to Slurm through it.
- **Keycloak and OIDC**: Keycloak is the sign-in service Vantage uses, and OIDC is the protocol it speaks. The cluster signs in with a client ID and secret and receives a short-lived token.
- **JWT signing key**: the key Slurm uses to sign and check the login tokens it hands out.
- **LDAP** is the user directory of your organization. The reconciler copies its users and groups into Slurm accounts.
- **Accounting operator**: a Slurm user allowed to see all jobs in the accounting database. `PrivateData=jobs` is the Slurm setting that hides jobs from other users.
- **systemd timer and path unit**: systemd features that start a service on a schedule (timer) or when a file appears (path unit).
- **systemd-setup**: a command each Vantage binary has that installs itself as a systemd service (its own user, directories and unit file).
- **ansible-vault**: Ansible's tool for keeping secrets encrypted in a file. `no_log` is the task setting that keeps a secret out of Ansible's output.
- **Presence agent**: a small program that tells Vantage this cluster is alive. A cluster with no presence agent shows as Not Connected.
- **OnCalendar** is a systemd schedule expression, such as `daily` or `*-*-* 03:00:00`.

## Variables

Required (the role fails when one is empty):

| Variable | Meaning |
| --- | --- |
| `vantage_agents_client_id` | The cluster's Keycloak client ID, which is the cluster ID. |
| `vantage_agents_client_secret` | The client secret. Keep it in `ansible-vault`. |
| `vantage_agents_oidc_base_url` | Keycloak base URL without `/realms/vantage`, for example `https://auth.vantagecompute.ai`. |
| `vantage_agents_ldap_url` | LDAP URL of your organization. |
| `vantage_agents_ldap_organization_id` | Your organization ID. |
| `vantage_agents_ldap_bind_password` | The LDAP bind password. Keep it in `ansible-vault`. |
| `vantage_agents_vref_api_url` | The base URL of vref-api. |
| `vantage_agents_api_base_url` | The base URL of the Vantage API the presence agent reports to, for example `https://apis.vantagecompute.ai`. |

Optional:

| Variable | Default | Meaning |
| --- | --- | --- |
| `vantage_agents_artifacts_url` | `https://vantage-artifacts.vantagecompute.ai` | Where the binaries are downloaded from. |
| `vantage_agents_reconciler_version` | `latest` | Reconciler version. Pin it in production. |
| `vantage_agents_vref_agent_version` | `latest` | vref-agent version. Pin it in production. |
| `vantage_agents_presence_agent_version` | `latest` | Presence agent version. Pin it in production. |
| `vantage_agents_slurmrestd_url` | `http://127.0.0.1:6820` | The cluster's slurmrestd. |
| `vantage_agents_slurm_user` | `slurm` | The user slurmctld runs as. |
| `vantage_agents_vref_container_engine` | empty | `pyxis` or `apptainer`; leave empty when the cluster runs neither. |
| `vantage_agents_slurm_token_lifespan` | `604800` | Seconds a vref-agent Slurm token lives. |
| `vantage_agents_slurm_token_refresh` | `daily` | A systemd `OnCalendar` value for re-minting it. |

## Example

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
    vantage_agents_vref_api_url: https://vref.example.com
    vantage_agents_api_base_url: https://apis.vantagecompute.ai
    vantage_agents_reconciler_version: "X.Y.Z"
    vantage_agents_vref_agent_version: "X.Y.Z"
  roles:
    - vantage_agents
```

## How it works

For each binary the role gets a Keycloak token with the cluster's credentials, downloads the binary and its `.sha256` file from the artifact CDN, and checks the checksum. When `/usr/bin` holds a different build it runs the binary's own `systemd-setup` command, which creates the service user, directories and unit. The role then writes the root-only (`0600`) settings files and starts the services. A second run changes nothing. Upgrading means changing the version variable and running again.

The role records what it installed, one line per binary (name, requested version, sha256), in `/etc/vantage/artifacts.lock`, the same file and format `v8x` writes.

The checksum comes from the same CDN as the binary, so it catches a damaged download, not a compromised CDN. Tasks that handle secrets use `no_log`.

For vref-agent the role also creates a `vrefagent` system user and mints a Slurm token for it with `scontrol token`, then refreshes it on a systemd timer, because the agent reads that token on every call and never mints one itself. The slurmctld wake-up hook is not wired: that means editing `slurm.conf`, which belongs to whoever owns your Slurm configuration. The vref repository's agent runbook (`docusaurus/docs/runbooks/agent-systemd-setup.md`) explains how to wire it.

## Leaving a component out

`vref-agent` and the presence agent carry the Ansible tags `vref_agent` and `presence_agent`. Run with `--skip-tags vref_agent` to leave `vref-agent` out.

Releases from 0.1.5 include the on-cluster agent and its `systemd-setup` command. The older 0.1.3 build is the cloud-side agent and has none, so the role stops with a clear message when it reaches that step.

## Testing

`just lint` runs ansible-lint. `just test <inventory>` runs the role twice against a throwaway Ubuntu 26.04 host that you point it at, with a stub token endpoint and artifact server, and checks that the second run changes nothing. It proves the Ansible logic only. It does not prove the real binaries, the real `systemd-setup`, or that a cluster shows up in Vantage; for that, apply the role to a host from the Vantage image with a real cluster.

## License

GPL-3.0-or-later. See `LICENSE`.
