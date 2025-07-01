.phony: ansible venv roles help
VENV := .venv/bin
SHELL = /usr/bin/env bash

ALL: ansible

venv: .venv/bin/activate

.venv/bin/activate: provisioning/requirements.txt
	test -d .venv || virtualenv .venv
	${VENV}/pip install --upgrade pip
	${VENV}/pip install -Ur provisioning/requirements.txt
	touch .venv/bin/activate

roles: provisioning/.roles-installed

provisioning/.roles-installed: venv provisioning/requirements.yml
	${VENV}/ansible-galaxy install -r provisioning/requirements.yml -p provisioning/roles
	touch provisioning/.roles-installed

ansible: venv roles ## Run Ansible on production
	${VENV}/ansible-playbook --user=root --inventory-file=provisioning/hosts provisioning/playbook.yml

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

up: ansible
	${VENV} vagrant up local

provision: ansible
	${VENV} vagrant provision local

local-deploy:
	bundle exec cap local deploy

production-deploy:
	bundle exec cap production deploy

clean:
	rm -rf .venv provisioning/.roles-installed 

services-up:
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml up --build -d
services-down:
	COMPOSE_PROJECT_NAME=morph-services docker compose -f docker_images/services.yaml down --remove-orphans

test:
	RAILS_ENV=test bundle exec rspec
