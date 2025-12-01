.PHONY: all clean deploy help lint \
        production-deploy production-provision provision \
        roles services-down services-up \
        share-web test up vagrant-plugins venv
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

production-ansible: venv roles ## Run Ansible on production
	${VENV}/ansible-playbook --user=root --inventory-file=provisioning/inventory/production provisioning/playbook.yml

staging-ansible: venv roles ## Run Ansible on production
	${VENV}/ansible-playbook --user=root --inventory-file=provisioning/inventory/staging.py provisioning/playbook.yml

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

production-provision: venv roles ## Provision production using ansible
	${VENV}/ansible-playbook --user=root --inventory-file=provisioning/hosts provisioning/playbook.yml

vagrant-deploy: ## Deploy app to local vagrant VM
	bundle exec cap local deploy

production-deploy: ## Deploy app to production
	bundle exec cap production deploy

docker-up: ## Full Docker environment including ruby containers (persistent data) BETA
	docker compose -f docker-compose.yml -f docker_images/persistent_services.yaml up

# Run up services required for CI (no persistence)
ci-services-up:
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml up --build -d redis elasticsearch

services-up: ## Run up services with persistent data (use SERVICES="redis elasticsearch" to exclude mysql)
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml -f docker_images/persistent_services.yaml up --build -d ${SERVICES}

services-down: ## Close down services required for CI / development
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml down --remove-orphans

services-logs: ## View logs for services (use SERVICES=elasticsearch for specific service)
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml logs $(SERVICES)

services-status: ## Check status of services
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml ps

test: ## Run rspec tests (Optionally add RUN_SLOW_TESTS=1 or DONT_RUN_DOCKER_TESTS=1)
	RAILS_ENV=test bundle exec rspec

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
	ngrok http ${PORT:-3000}

staging-deploy:
	bundle exec cap staging deploy

