# Recipes for the vantage_agents role. Run `just` to list them.

default:
    @just --list

# Lint the role.
lint:
    uvx ansible-lint

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
