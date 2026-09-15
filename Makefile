.PHONY: all clean help lint \
        production-check production-deploy production-provision \
        roles services-down services-up \
	staging-deploy staging-provision \
        share-web test vagrant-plugins venv \
	all-tests quick-tests \
	devcontainer-up devcontainer-shell docker-up \
	dev-scraper-images dev-scraper-network ssh-known-hosts
VENV := .venv/bin
SHELL := /bin/bash
PYTHON_VERSION := $(shell cat .python-version 2>/dev/null || echo "python3")
# So inventory uses .venv
export PATH := $(CURDIR)/$(VENV):$(PATH)

all: help

venv: .venv/bin/activate

.venv/bin/activate: provisioning/requirements.txt
	test -d .venv || virtualenv -p $(PYTHON_VERSION) .venv
	${VENV}/pip install --upgrade pip
	${VENV}/pip install -Ur provisioning/requirements.txt
	touch .venv/bin/activate

roles: provisioning/.roles-installed

provisioning/.roles-installed: venv provisioning/requirements.yml
	${VENV}/ansible-galaxy install -r provisioning/requirements.yml -p provisioning/roles
	touch provisioning/.roles-installed

ANSIBLE_TAGS := $(shell echo "$(TAGS)" | sed 's/[^A-Z0-9_]\+/,/gi' | sed 's/,\+/,/g' | sed 's/^,//' | sed 's/,$$//')
ANSIBLE_SKIP_TAGS := $(shell echo "$(SKIP_TAGS)" | sed 's/[^A-Z0-9_]\+/,/gi' | sed 's/,\+/,/g' | sed 's/^,//' | sed 's/,$$//')
ANSIBLE_START_TASK := $(if $(START_AT_TASK),*$(shell echo "$(START_AT_TASK)" | sed 's/[^A-Z0-9_]\+/*/gi')*,)

# Build ansible-playbook options just like Vagrantfile
ANSIBLE_OPTS :=
ifdef ANSIBLE_TAGS
ANSIBLE_OPTS += --tags "$(ANSIBLE_TAGS)"
$(info INFO: Only running TAGS: $(ANSIBLE_TAGS))
endif
ifdef ANSIBLE_SKIP_TAGS
ANSIBLE_OPTS += --skip-tags "$(ANSIBLE_SKIP_TAGS)"
$(info INFO: Skipping TAGS: $(ANSIBLE_SKIP_TAGS))
endif
ifdef ANSIBLE_VERBOSE
ANSIBLE_OPTS += -$(ANSIBLE_VERBOSE)
$(info INFO: Setting verbose: -$(ANSIBLE_VERBOSE))
endif
ifdef ANSIBLE_START_TASK
ANSIBLE_OPTS += --start-at-task "$(ANSIBLE_START_TASK)"
$(info INFO: Starting at task matching: $(ANSIBLE_START_TASK))
endif

help: ## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-30s %s\n" "Target" "Description" ; \
	printf "%-30s %s\n" "------" "-----------" ; \
	for help_line in $${help_lines[@]}; do \
		IFS=$$':' ; \
		help_split=($$help_line) ; \
		help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		printf '\033[36m'; \
		printf "%-30s %s" $$help_command ; \
		printf '\033[0m'; \
		printf "%s\n" $$help_info; \
	done

 # Ensure required Vagrant plugins are installed
vagrant-plugins:
	@installed_plugins=$$(vagrant plugin list); \
	for plugin in vagrant-hostsupdater vagrant-disksize vagrant-vbguest; do \
		if echo "$$installed_plugins" | grep -q $$plugin; then \
			[ "$(MAKECMDGOALS)" != "vagrant-plugins" ] || echo "$$plugin plugin is already installed"; \
		else \
			vagrant plugin install $$plugin; \
		fi; \
	done

vagrant-up: venv roles vagrant-plugins ## launch local vagrant VM
	vagrant up local

vagrant-provision: venv roles vagrant-plugins ## Provision local vagrant VM using ansible
	vagrant provision local

staging-provision: venv roles ## Provision staging using ansible
	${VENV}/ansible-playbook --user=root $(ANSIBLE_OPTS) --inventory-file=provisioning/inventory/staging.py provisioning/playbook.yml

production-provision: venv roles ## Provision production using ansible
	${VENV}/ansible-playbook --user=root $(ANSIBLE_OPTS) --inventory-file=provisioning/inventory/production provisioning/playbook.yml

production-check: venv roles ## Dry-run the ansible playbook against production (--check --diff, makes no changes)
	${VENV}/ansible-playbook --user=root $(ANSIBLE_OPTS) --check --diff --inventory-file=provisioning/inventory/production provisioning/playbook.yml

vagrant-deploy: ## Deploy app to local vagrant VM
	bundle exec cap local deploy

staging-deploy: ## Deploy app to staging
	bundle exec cap staging deploy

production-deploy: ## Deploy app to production
	bundle exec cap production deploy

# The ruby containers bind-mount this file, and compose is told not to invent a
# missing source (see docker-compose.yml), so a host that has never used ssh
# needs it created before anything starts. The devcontainer does this for itself
# through initializeCommand.
ssh-known-hosts:
	@[ -d "$${HOME}/.ssh" ] || mkdir -m 700 "$${HOME}/.ssh"
	@touch "$${HOME}/.ssh/known_hosts"

docker-up: ssh-known-hosts ## Full Docker environment including ruby containers (persistent data)
	docker compose -f docker-compose.yml -f docker_images/persistent_services.yaml up

devcontainer-up: ## Build and start the containerised dev environment via the devcontainer CLI
	devcontainer up --workspace-folder .

devcontainer-shell: ## Open a shell in the running devcontainer (SSH agent forwarded)
	devcontainer exec --workspace-folder . bash

# On Apple silicon (containerd image store) the buildstep tags that are
# manifest lists must be pulled by their amd64 manifest digest, or the
# legacy builder used for scraper compiles fails with "no match for
# platform in manifest" (see ADR 0006).
dev-scraper-images: ## Pull the buildstep scraper base images in a form that works in the containerised dev environment
	for tag in cedar-14 heroku-18 heroku-24; do \
		digest=$$(docker buildx imagetools inspect openaustralia/buildstep:$$tag --format '{{ if .Manifest.Manifests }}{{ range .Manifest.Manifests }}{{ if and (eq .Platform.Architecture "amd64") (eq .Platform.OS "linux") }}{{ .Digest }}{{ end }}{{ end }}{{ end }}'); \
		if [ -n "$$digest" ]; then \
			docker pull openaustralia/buildstep@$$digest && \
			docker tag openaustralia/buildstep@$$digest openaustralia/buildstep:$$tag; \
		else \
			docker pull --platform linux/amd64 openaustralia/buildstep:$$tag; \
		fi; \
	done

# Morph::DockerRunner creates this network with subnet 192.168.0.0/16, which
# fails on a dev machine where any other Docker network already sits in that
# range. Pre-creating it without a fixed subnet lets Docker pick a free one;
# the app uses the network if it already exists.
dev-scraper-network: ## Create the "morph" scraper network with an auto-allocated subnet (dev machines only)
	docker network inspect morph >/dev/null 2>&1 || \
		docker network create --driver bridge \
			-o com.docker.network.bridge.name=morph \
			-o com.docker.network.bridge.enable_icc=false \
			morph

# Run up services required for CI (no persistence)
ci-services-up:
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml up --build -d redis elasticsearch

services-up: ## Run up services with persistent data (use SERVICES="redis elasticsearch" to exclude mysql)
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml -f docker_images/persistent_services.yaml up --build -d $${SERVICES}

services-down: ## Close down services required for CI / development
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml down --remove-orphans

services-logs: ## View logs for services (use SERVICES=elasticsearch for specific service)
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml logs $${SERVICES}

services-status: ## Check status of services
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml ps

rspec: ## Run all rspec tests (Optionally add DONT_RUN_DOCKER_TESTS=1 or DONT_RUN_GITHUB_TESTS=1)
	RAILS_ENV=test bundle exec rspec

test: quick-tests all-tests ## Run quick test then everything for a full coverage/index.html report

quick-tests: ## Run quick rspec tests (excludes slow, docker and github tests)
	DONT_RUN_GITHUB_TESTS=1 DONT_RUN_DOCKER_TESTS=1 bundle exec rake
	echo "Passed quick tests!"

ci-tests: ## Run the same rspec tests as CI (slow but not docker nor github app tests)
	DONT_RUN_DOCKER_TESTS=1 RUN_SLOW_TESTS=1 DONT_RUN_GITHUB_TESTS=1 bundle exec rake
	echo "Passed CI tests!"

all-tests: ## Run all rspec tests
	RUN_SLOW_TESTS=1 bundle exec rake
	echo "Passed all tests!"

lint: ## Lint code
	bundle exec rubocop
	bundle exec haml-lint

clean: ## Clean out venv, installed roles and rails tmp/cache
	[ -f provisioning/requirements.yml ] && $(VENV)/ansible-galaxy remove -r provisioning/requirements.yml -p provisioning/roles || true
	rm -rf .venv provisioning/.roles-installed tmp/cache

clobber: clean ## Remove everything including logs
	rm -f log/*.log

docker-clean: services-down ## Remove all Docker resources INCLUDING databases in volumes
	docker system prune -af --volumes

share-web: ## Share web server on port 3000 to the internet (use PORT=N to use an alternative port)
	ngrok http $${PORT:-3000}

mailcatcher: ## run mailcatcher to catch development emails
	bundle exec mailcatcher
