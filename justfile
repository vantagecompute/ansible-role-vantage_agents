# Recipes for the vantage_agents role. Run `just` to list them.

default:
    @just --list

# Lint the role. ansible-lint lists every plugin through ansible-doc, and
# ansible-core 2.22 answers with deprecation warnings for its own oneline and
# tree callbacks. They say nothing about this role, so they are silenced here;
# ansible-lint's own deprecation rules still run.
lint:
    ANSIBLE_DEPRECATION_WARNINGS=False uvx ansible-lint

# Check the playbooks parse.
syntax:
    ansible-playbook --syntax-check -i localhost, tests/converge.yml

# Run the role twice against a throwaway Ubuntu 26.04 host and check that the
# second run changes nothing. The host must be disposable: the test installs
# stub services and a stub artifact server. It proves the role's Ansible logic
# only; real verification needs a host from the Vantage image and a real
# cluster. Usage: just test <inventory>, where <inventory> is an inventory
# file or a host followed by a comma, such as "ubuntu@10.0.0.5,".
test inventory:
    ansible-playbook -i {{inventory}} tests/prepare.yml
    ansible-playbook -i {{inventory}} tests/converge.yml
    ansible-playbook -i {{inventory}} tests/converge.yml | tee "${TMPDIR:-/tmp}/vantage-agents-second-run.log"
    grep -E 'changed=0 .*failed=0' "${TMPDIR:-/tmp}/vantage-agents-second-run.log"
    ansible-playbook -i {{inventory}} tests/verify.yml

# Install the documentation site's dependencies.
docs-install:
    cd docusaurus && yarn install

# Start the documentation site locally, reloading as you edit.
docs-dev: docs-install
    cd docusaurus && yarn start

# Build the documentation site. A broken link fails the build.
docs-build: docs-install
    cd docusaurus && yarn build

# Build the documentation site and serve the result.
docs-serve: docs-build
    cd docusaurus && yarn serve

# Remove the documentation site's build output.
docs-clean:
    cd docusaurus && rm -rf build .docusaurus

# Usage: just release 0.1.0. CI then publishes that version to Ansible Galaxy
# as vantagecompute.vantage_agents and deploys the documentation site.
# Tag a release from main and push the tag.
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    VERSION="{{version}}"

    # The same pattern the Release and Deploy docs workflows trigger on. A tag
    # that does not match would be pushed and then ignored by both.
    if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Version '${VERSION}' is not valid. Use three numbers such as 1.2.3, with no leading v." >&2
        exit 1
    fi

    if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
        echo "Releases are tagged from main. Switch to main first." >&2
        exit 1
    fi

    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Working tree is not clean. Commit or stash changes before releasing." >&2
        exit 1
    fi

    git fetch --quiet --tags origin main
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
        echo "main differs from origin/main. Pull or push first, so the tag names a commit that is on GitHub." >&2
        exit 1
    fi

    if git rev-parse --verify --quiet "refs/tags/${VERSION}" >/dev/null; then
        echo "Tag ${VERSION} already exists." >&2
        exit 1
    fi

    echo "Linting the role before tagging..."
    just lint

    git tag -a "${VERSION}" -m "Release ${VERSION}"
    git push origin "${VERSION}"
    echo "Released ${VERSION} -- CI will publish it to Ansible Galaxy and deploy the docs."
