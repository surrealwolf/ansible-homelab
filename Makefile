# Paths
WORKDIR ?= /code
PWD ?= $(shell pwd)
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

# Docker options
DOCKER_CONFIG_MAP = -v $(PWD):$(WORKDIR) -v $(PWD)/$(SSH_PATH):/root/.ssh -v $(PWD)/$(CONFIG):/etc/ansible/ansible.cfg
DOCKER_INIT_MAP = -v $(PWD):$(WORKDIR)
DOCKER_ROLE_MAP = -v $(ROLE):$(WORKDIR)
DOCKER_OPTS ?= --rm --env EDITOR=nano
DOCKER_NAME = --name ansible ansible:dev

# Docker commands
DOCKER_BUILD ?= docker build
DOCKER_IT ?= docker run -it $(DOCKER_OPTS) $(DOCKER_CONFIG_MAP) $(DOCKER_NAME)
DOCKER_INIT ?= docker run $(DOCKER_OPTS) $(DOCKER_INIT_MAP) $(DOCKER_NAME)
DOCKER_ROLE ?= docker run $(DOCKER_OPTS) $(DOCKER_ROLE_MAP) $(DOCKER_NAME)
DOCKER_RUN ?= docker run $(DOCKER_OPTS) $(DOCKER_CONFIG_MAP) $(DOCKER_NAME)

.PHONY: build
build:
	docker rm -f ansible
	$(DOCKER_BUILD) -t ansible:dev .

.PHONY: bash
bash: build
	$(DOCKER_IT) bash

# make create-role name=<role name>
create-role: build
	$(DOCKER_ROLE) ansible-galaxy role init $(name)

# make copy-id host=<name or ip>
copy-id: build
	$(DOCKER_IT) ssh-copy-id -i $(SSH_KEY) $(ANSIBLE_USER)@$(host)

decrypt: build
	$(DOCKER_RUN) ansible-vault decrypt $(VAULT)

encrypt: build
	$(DOCKER_RUN) ansible-vault encrypt $(VAULT)

lint: build
	$(DOCKER_RUN) ansible-lint

ping: build
	$(DOCKER_RUN) ansible -i $(WORKDIR)/inventory/ash.yaml all -m ping

# make check-playbook file=<playbook filename>
check-playbook: fix-lines fix-root
	$(ANSIBLE_CHECK)/$(file)

# make run-playbook file=<playbook filename>
run-playbook: fix-lines fix-root
	$(ANSIBLE_RUN)/$(file)

.PHONY: test-artifactory
test-artifactory: build
	$(DOCKER_RUN) make check-playbook file=artifactory.yml

.PHONY: test-bitwarden
test-bitwarden: build
	$(DOCKER_RUN) make check-playbook file=bitwarden-server.yml

.PHONY: test-ca
test-ca: build
	$(DOCKER_RUN) make check-playbook file=ca.yml

.PHONY: test-dns
test-dns: build
	$(DOCKER_RUN) make check-playbook file=dns.yml

.PHONY: test-checkmk
test-checkmk: build
	$(DOCKER_RUN) make check-playbook file=checkmk-server.yml

.PHONY: test-gitlab
test-gitlab: build
	$(DOCKER_RUN) make check-playbook file=gitlab.yml

.PHONY: test-gitlab-runner
test-gitlab-runner: build
	$(DOCKER_RUN) make check-playbook file=gitlab-runner.yml

.PHONY: test-sql
test-sql: build
	$(DOCKER_RUN) make check-playbook file=mssql.yml
	$(DOCKER_RUN) make check-playbook file=postgresql.yml

.PHONY: test-ntpd
test-ntpd: build
	$(DOCKER_RUN) make check-playbook file=ntpd.yml

.PHONY: test-lb
test-lb: build
	$(DOCKER_RUN) make check-playbook file=loadbalancer.yml

.PHONY: test-rke2
test-rke2: build
	$(DOCKER_RUN) make check-playbook file=rke2-server.yml

.PHONY: test-rke2-template
test-rke2-template: build
	$(DOCKER_RUN) make check-playbook file=rke2-template.yml

.PHONY: test-template
test-template: build
	$(DOCKER_RUN) make check-playbook file=template.yml

.PHONY: test-twingate
test-twingate: build
	$(DOCKER_RUN) make check-playbook file=twingate.yml

.PHONY: test-xcpng
test-xcpng: build
	$(DOCKER_RUN) make check-playbook file=xcpng.yml

.PHONY: test-vault
test-vault: build
	$(DOCKER_RUN) make check-playbook file=vault.yml

.PHONY: test
test: test-dns test-ca test-checkmk test-sql test-gitlab test-twingate test-lb test-rke2

.PHONY: deploy-artifactory
deploy-artifactory: build
	$(DOCKER_RUN) make run-playbook file=artifactory.yml

.PHONY: deploy-bitwarden
deploy-bitwarden: build
	$(DOCKER_RUN) make run-playbook file=bitwarden-server.yml

.PHONY: deploy-ca
deploy-ca: build
	$(DOCKER_RUN) make run-playbook file=ca.yml

.PHONY: deploy-dns
deploy-dns: build
	$(DOCKER_RUN) make run-playbook file=dns.yml

.PHONY: deploy-checkmk
deploy-checkmk: build
	$(DOCKER_RUN) make run-playbook file=checkmk-server.yml

.PHONY: deploy-gitlab
deploy-gitlab: build
	$(DOCKER_RUN) make run-playbook file=gitlab.yml

.PHONY: deploy-gitlab-runner
deploy-gitlab-runner: build
	$(DOCKER_RUN) make run-playbook file=gitlab-runner.yml

.PHONY: deploy-lb
deploy-lb: build
	$(DOCKER_RUN) make run-playbook file=loadbalancer.yml

.PHONY: deploy-sql
deploy-sql: build
	$(DOCKER_RUN) make run-playbook file=postgresql.yml

.PHONY: deploy-ntpd
deploy-ntpd: build
	$(DOCKER_RUN) make run-playbook file=ntpd.yml

.PHONY: deploy-rke2
deploy-rke2: build
	$(DOCKER_RUN) make run-playbook file=rke2-server.yml

.PHONY: deploy-rke2-template
deploy-rke2-template: build
	$(DOCKER_RUN) make run-playbook file=rke2-template.yml

.PHONY: deploy-template
deploy-template: build
	$(DOCKER_RUN) make run-playbook file=template.yml

.PHONY: deploy-twingate
deploy-twingate: build
	$(DOCKER_RUN) make run-playbook file=twingate.yml

.PHONY: deploy-xcpng
deploy-xcpng: build
	$(DOCKER_RUN) make run-playbook file=xcpng.yml

.PHONY: deploy-vault
deploy-vault: build
	$(DOCKER_RUN) make run-playbook file=vault.yml

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
	$(DOCKER_INIT) ansible-config init --disabled --type all > $(CONFIG)
	sed -i '0,/$(PKEY_STRING_REGEX)/s/$(PKEY_STRING_REGEX)/$(PKEY_STRING_CFG)/g' $(CONFIG)
	sed -i '0,/$(USER_STRING_REGEX)/s/$(USER_STRING_REGEX)/$(USER_STRING_CFG)/g' $(CONFIG)
	sed -i '0,/$(ROLE_STRING_REGEX)/s/$(ROLE_STRING_REGEX)/$(ROLE_STRING_CFG)/g' $(CONFIG)
	sed -i '0,/$(VAULT_STRING_REGEX)/s/$(VAULT_STRING_REGEX)/$(VAULT_STRING_CFG)/g' $(CONFIG)

init-ssh: build
	touch $(SSH_AUTH) $(SSH_CONFIG) $(SSH_HOST)
	$(DOCKER_IT) ssh-keygen -f $(SSH_KEY) -t ed25519 -C ansible -N ''
	nano $(SSH_CONFIG)

init-vault: build
	$(DOCKER_IT) ansible-vault create --vault-password-file $(VAULT_KEY) $(VAULT)

.PHONY: fix-lines
fix-lines:
	dos2unix $(SSH_CONFIG)
	dos2unix $(SSH_KEY)
	dos2unix $(CONFIG)
	dos2unix $(VAULT_KEY)

.PHONY: fix-root
fix-root:
	chmod 600 /root/$(SSH_CONFIG)
	chmod 600 /root/$(SSH_KEY)

.PHONY: fix-perms
fix-perms:
	chmod 600 $(SSH_CONFIG)
	chmod 400 $(SSH_KEY)
	chmod 600 $(CONFIG)
	chmod 400 $(VAULT_KEY)
