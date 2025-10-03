.PHONY: all clean deploy help lint \
        production-deploy production-provision provision \
        roles services-down services-up \
        test up vagrant-plugins venv
VENV := .venv/bin
SHELL := /bin/bash
PYTHON_VERSION := $(shell cat .python-version 2>/dev/null || echo "python3")

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

vagrant-plugins: ## Ensure required Vagrant plugins are installed
	@for plugin in vagrant-hostsupdater vagrant-disksize vagrant-vbguest; do \
		vagrant plugin list | grep -q $$plugin || vagrant plugin install $$plugin; \
	done

help: ## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-30s %s\n" "target" "help" ; \
	printf "%-30s %s\n" "------" "----" ; \
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

up: venv roles vagrant-plugins ## launch local vagrant VM
	vagrant up local

provision: venv roles vagrant-plugins ## Provision local vagrant VM using ansible
	vagrant provision local

production-provision: venv roles ## Provision production using ansible
	${VENV}/ansible-playbook --user=root --inventory-file=provisioning/hosts provisioning/playbook.yml

deploy: ## Deploy app to local vagrant VM
	bundle exec cap local deploy

production-deploy: ## Deploy app to production
	bundle exec cap production deploy

services-up: ## Run up services required for CI / development (not MySQL)
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml up --build -d

services-down: ## Run up services required for CI / development
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml down --remove-orphans

test: ## Run rspec tests
	RAILS_ENV=test bundle exec rspec

lint: ## Lint code
	bundle exec rubocop
	bundle exec haml-lint

clean: ## Clean out venv, installed roles and rails tmp/cache
	[ -f provisioning/requirements.yml ] && $(VENV)/ansible-galaxy remove -r provisioning/requirements.yml -p provisioning/roles || true
	rm -rf .venv provisioning/.roles-installed tmp/cache

clobber: clean ## Remove everything including logs
	rm -f log/*.log

docker-clean: services-down ## Remove all Docker resources
	docker system prune -af --volumes
