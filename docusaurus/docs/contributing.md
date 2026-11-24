---
title: Contributing
description: How to lint, test, document and release the vantage_agents role
---

## Set up

You need [just](https://github.com/casey/just), [uv](https://docs.astral.sh/uv/) and Ansible 2.16
or newer. The documentation site also needs Node 26 or newer and Yarn.

```bash
git clone https://github.com/vantagecompute/ansible-role-vantage_agents
cd ansible-role-vantage_agents
just --list
```

## Repository layout

| Path | What it holds |
|---|---|
| `defaults/main.yml` | The role's inputs and their defaults |
| `vars/main.yml` | Constants that are not inputs |
| `tasks/` | One file per component, plus the checks, the token and the download |
| `templates/` | The settings files and the token refresh units |
| `handlers/` | Service restarts |
| `meta/main.yml` | The role's name, namespace and supported platforms on Ansible Galaxy |
| `tests/` | Playbooks that run the role against a throwaway host |
| `docusaurus/` | This documentation site |

## Lint

```bash
just lint
just syntax
```

## Test

```bash
just test "ubuntu@10.0.0.5,"
```

`just test` takes an inventory file, or a host followed by a comma. It runs the role twice against
that host with a stub token endpoint and a stub artifact server, checks that the second run
changes nothing, and then verifies the result.

The host must be a throwaway Ubuntu 26.04 machine: the test installs stub services on it.

The test proves the Ansible logic only. It does not prove the real binaries, the real
`systemd-setup`, or that a cluster shows up in Vantage. For that, apply the role to a host from
the Vantage image with a real cluster.

## Documentation

```bash
just docs-dev     # local server that reloads as you edit
just docs-build   # fails on a broken link
```

When you add or change an input, update [Variables](./variables.md) and the README.

## Commit messages

Commit messages follow the conventional format checked by commitlint on every pull request:

```
<type>[(<scope>)]: <summary>
```

The type is one of `fix`, `feat`, `cherry-pick`, `chore`, `security`, `ci`, `docs`, `test`,
`refactor`, `perf` or `release`.

## Release

A release is a git tag made of three numbers, such as `0.2.0`, with no leading `v`.

```bash
just release 0.2.0
```

The recipe checks that you are on an up-to-date, clean `main`, lints the role, then creates and
pushes the tag. The tag starts two workflows:

| Workflow | What it does |
|---|---|
| Release | Imports that version into Ansible Galaxy as `vantagecompute.vantage_agents` |
| Deploy docs | Builds this site and publishes it |

A tag cannot be reused once it is on Ansible Galaxy. To fix a release, publish the next version.
