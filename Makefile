# Paths
WORKDIR ?= /code
PWD ?= $(shell pwd)
USER ?= $(USERNAME)
CONFIG ?= ansible.cfg
INVENTORY ?= inventory/ash.yaml
PLAYBOOK ?= $(WORKDIR)/playbooks
ROLE ?= $(PWD)/roles
SSH_PATH ?= .ssh
SSH_AUTH ?= $(SSH_PATH)/authorized_keys
SSH_CONFIG ?= $(SSH_PATH)/config
SSH_HOST ?= $(SSH_PATH)/known_hosts
SSH_KEY ?= $(SSH_PATH)/ansible
VAULT_PATH ?= vault
VAULT ?= $(VAULT_PATH)/ash.yml
VAULT_KEY ?= vault.key

# Commands
ANSIBLE_CHECK = ansible-playbook --check --inventory $(INVENTORY) $(PLAYBOOK)
ANSIBLE_RUN = ansible-playbook --inventory $(INVENTORY) $(PLAYBOOK)
ANSIBLE_USER ?= ansible

# Pattern matching and replacement
USER_STRING_REGEX = ;remote_user=
USER_STRING_CFG = remote_user=$(ANSIBLE_USER)
PKEY_STRING_REGEX = ;private_key_file=
PKEY_STRING_CFG = private_key_file=\/code\/.ssh\/ansible
ROLE_STRING_REGEX = ;roles_path={{ ANSIBLE_HOME ~ \"\/roles:\/usr\/share\/ansible\/roles:\/etc\/ansible\/roles\:\/root\/.ansible\/roles" }}
ROLE_STRING_CFG = roles_path=\/roles:\/code\/roles:\/etc\/ansible\/roles
VAULT_STRING_REGEX = ;vault_password_file=
VAULT_STRING_CFG = vault_password_file=\/code\/vault.key

# podman options
PODMAN_CONFIG_MAP = -v $(PWD):$(WORKDIR) -v $(PWD)/$(SSH_PATH):/root/.ssh -v $(PWD)/$(CONFIG):/etc/ansible/ansible.cfg
PODMAN_INIT_MAP = -v $(PWD):$(WORKDIR)
PODMAN_ROLE_MAP = -v $(ROLE):$(WORKDIR)
PODMAN_UID ?= $(shell id -u)
PODMAN_GID ?= $(shell id -g)
PODMAN_OPTS ?= --rm --env EDITOR=nano
PODMAN_NAME = --name ansible ansible:dev

# podman commands
PODMAN_BUILD ?= podman build
PODMAN_IT ?= podman run -it $(PODMAN_OPTS) $(PODMAN_CONFIG_MAP) $(PODMAN_NAME)
PODMAN_INIT ?= podman run $(PODMAN_OPTS) $(PODMAN_INIT_MAP) $(PODMAN_NAME)
PODMAN_ROLE ?= podman run $(PODMAN_OPTS) $(PODMAN_ROLE_MAP) $(PODMAN_NAME)
PODMAN_RUN ?= podman run $(PODMAN_OPTS) $(PODMAN_CONFIG_MAP) $(PODMAN_NAME)

# windows permission
READ = 'R'
MAX = '(MA)'

.PHONY: build
build: fix-lines fix-perms
	podman rm -f ansible
	$(PODMAN_BUILD) -t ansible:dev .

.PHONY: bash
bash: build
	$(PODMAN_IT) bash

# make create-role name=<role name>
create-role: build
	$(PODMAN_ROLE) ansible-galaxy role init $(name)

# make copy-id host=<name or ip>
copy-id: build
	$(PODMAN_IT) ssh-copy-id -i $(SSH_KEY) $(ANSIBLE_USER)@$(host)

decrypt: build
	$(PODMAN_RUN) ansible-vault decrypt $(VAULT)

encrypt: build
	$(PODMAN_RUN) ansible-vault encrypt $(VAULT)

lint: build
	$(PODMAN_RUN) ansible-lint

ping: build
	$(PODMAN_RUN) ansible -i $(WORKDIR)/inventory/ash.yaml all -m ping

# make check-playbook file=<playbook filename>
check-playbook:
	$(ANSIBLE_CHECK)/$(file)

# make run-playbook file=<playbook filename>
run-playbook:
	$(ANSIBLE_RUN)/$(file)

.PHONY: test-artifactory
test-artifactory: build
	$(PODMAN_RUN) make check-playbook file=artifactory.yml

.PHONY: test-bitwarden
test-bitwarden: build
	$(PODMAN_RUN) make check-playbook file=bitwarden-server.yml

.PHONY: test-ca
test-ca: build
	$(PODMAN_RUN) make check-playbook file=ca.yml

.PHONY: test-dns
test-dns: build
	$(PODMAN_RUN) make check-playbook file=dns.yml

.PHONY: test-checkmk
test-checkmk: build
	$(PODMAN_RUN) make check-playbook file=checkmk-server.yml

.PHONY: test-gitlab
test-gitlab: build
	$(PODMAN_RUN) make check-playbook file=gitlab.yml

.PHONY: test-gitlab-runner
test-gitlab-runner: build
	$(PODMAN_RUN) make check-playbook file=gitlab-runner.yml

.PHONY: test-sql
test-sql: build
	$(PODMAN_RUN) make check-playbook file=mssql.yml
	$(PODMAN_RUN) make check-playbook file=postgresql.yml

.PHONY: test-ntpd
test-ntpd: build
	$(PODMAN_RUN) make check-playbook file=ntpd.yml

.PHONY: test-lb
test-lb: build
	$(PODMAN_RUN) make check-playbook file=loadbalancer.yml

.PHONY: test-rke2
test-rke2: build
	$(PODMAN_RUN) make check-playbook file=rke2-server.yml

.PHONY: test-rke2-template
test-rke2-template: build
	$(PODMAN_RUN) make check-playbook file=rke2-template.yml

.PHONY: test-template
test-template: build
	$(PODMAN_RUN) make check-playbook file=template.yml

.PHONY: test-twingate
test-twingate: build
	$(PODMAN_RUN) make check-playbook file=twingate.yml

.PHONY: test-xcpng
test-xcpng: build
	$(PODMAN_RUN) make check-playbook file=xcpng.yml

.PHONY: test-vault
test-vault: build
	$(PODMAN_RUN) make check-playbook file=vault.yml

.PHONY: test
test: test-dns test-ca test-checkmk test-sql test-gitlab test-twingate test-lb test-rke2

.PHONY: deploy-artifactory
deploy-artifactory: build
	$(PODMAN_RUN) make run-playbook file=artifactory.yml

.PHONY: deploy-bitwarden
deploy-bitwarden: build
	$(PODMAN_RUN) make run-playbook file=bitwarden-server.yml

.PHONY: deploy-ca
deploy-ca: build
	$(PODMAN_RUN) make run-playbook file=ca.yml

.PHONY: deploy-dns
deploy-dns: build
	$(PODMAN_RUN) make run-playbook file=dns.yml

.PHONY: deploy-checkmk
deploy-checkmk: build
	$(PODMAN_RUN) make run-playbook file=checkmk-server.yml

.PHONY: deploy-gitlab
deploy-gitlab: build
	$(PODMAN_RUN) make run-playbook file=gitlab.yml

.PHONY: deploy-gitlab-runner
deploy-gitlab-runner: build
	$(PODMAN_RUN) make run-playbook file=gitlab-runner.yml

.PHONY: deploy-lb
deploy-lb: build
	$(PODMAN_RUN) make run-playbook file=loadbalancer.yml

.PHONY: deploy-sql
deploy-sql: build
	$(PODMAN_RUN) make run-playbook file=postgresql.yml

.PHONY: deploy-ntpd
deploy-ntpd: build
	$(PODMAN_RUN) make run-playbook file=ntpd.yml

.PHONY: deploy-rke2
deploy-rke2: build
	$(PODMAN_RUN) make run-playbook file=rke2-server.yml

.PHONY: deploy-rke2-template
deploy-rke2-template: build
	$(PODMAN_RUN) make run-playbook file=rke2-template.yml

.PHONY: deploy-template
deploy-template: build
	$(PODMAN_RUN) make run-playbook file=template.yml

.PHONY: deploy-twingate
deploy-twingate: build
	$(PODMAN_RUN) make run-playbook file=twingate.yml

.PHONY: deploy-xcpng
deploy-xcpng: build
	$(PODMAN_RUN) make run-playbook file=xcpng.yml

.PHONY: deploy-vault
deploy-vault: build
	$(PODMAN_RUN) make run-playbook file=vault.yml

.PHONY: deploy
deploy: deploy-dns deploy-ca deploy-checkmk deploy-sql deploy-gitlab deploy-twingate deploy-lb deploy-rke2

# Init functions
.PHONY: init
init: init-clean init-cfg init-ssh fix-perms init-vault

.PHONY: init-clean
init-clean:
	rm -rf $(SSH_PATH) & mkdir $(SSH_PATH)
	rm -rf $(VAULT_PATH) & mkdir $(VAULT_PATH)

init-cfg: build
	$(PODMAN_INIT) ansible-config init --disabled --type all > $(CONFIG)
	sed -i '0,/$(PKEY_STRING_REGEX)/s/$(PKEY_STRING_REGEX)/$(PKEY_STRING_CFG)/g' $(CONFIG)
	sed -i '0,/$(USER_STRING_REGEX)/s/$(USER_STRING_REGEX)/$(USER_STRING_CFG)/g' $(CONFIG)
	sed -i '0,/$(ROLE_STRING_REGEX)/s/$(ROLE_STRING_REGEX)/$(ROLE_STRING_CFG)/g' $(CONFIG)
	sed -i '0,/$(VAULT_STRING_REGEX)/s/$(VAULT_STRING_REGEX)/$(VAULT_STRING_CFG)/g' $(CONFIG)

init-ssh: build
	touch $(SSH_AUTH) $(SSH_CONFIG) $(SSH_HOST)
	$(PODMAN_IT) ssh-keygen -f $(SSH_KEY) -t ed25519 -C ansible -N ''
	nano $(SSH_CONFIG)

init-vault: build
	$(PODMAN_IT) ansible-vault create --vault-password-file $(VAULT_KEY) $(VAULT)

.PHONY: modify-perms
modify-perms:
ifeq ($(OS),Windows_NT)
	icacls $(SSH_CONFIG) /reset
	icacls $(SSH_CONFIG) /grant:r $(USER):M
	icacls $(SSH_CONFIG) /inheritance:r
	icacls $(CONFIG) /reset
	icacls $(CONFIG) /grant:r $(USER):M
	icacls $(CONFIG) /inheritance:r
	icacls $(VAULT_KEY) /reset
	icacls $(VAULT_KEY) /grant:r $(USER):M
	icacls $(VAULT_KEY) /inheritance:r
else
	chmod 700 $(SSH_CONFIG)
	chmod 700 $(CONFIG)
	chmod 700 $(VAULT_KEY)
endif

.PHONY: fix-lines
fix-lines: modify-perms
	dos2unix $(SSH_CONFIG)
	dos2unix $(CONFIG)
	dos2unix $(VAULT_KEY)

.PHONY: fix-perms
fix-perms:
ifeq ($(OS),Windows_NT)
	icacls $(SSH_CONFIG) /reset
	icacls $(SSH_CONFIG) /grant:r $(USER):$(READ)
	icacls $(SSH_CONFIG) /inheritance:r	
	icacls $(CONFIG) /reset
	icacls $(CONFIG) /grant:r $(USER):$(READ)	
	icacls $(CONFIG) /inheritance:r
	icacls $(VAULT_KEY) /reset
	icacls $(VAULT_KEY) /grant:r $(USER):$(READ)
	icacls $(VAULT_KEY) /inheritance:r
else
	chmod 600 $(SSH_CONFIG)
	chmod 600 $(CONFIG)
	chmod 400 $(VAULT_KEY)
endif
