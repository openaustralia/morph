# Provision the new server from the infrastructure repository

Status: accepted

morph is the last OAF service provisioned from its own repository
(`morph/provisioning`). The new Ubuntu 24.04 server is provisioned from
[openaustralia/infrastructure](https://github.com/openaustralia/infrastructure)
(Terraform + Ansible) instead, closing infrastructure#341: it reuses the
shared roles (base-server, mysql, deploy-user, backups, certbot) and the
shared Ansible Vault, and brings morph in line with how PlanningAlerts,
RightToKnow and TheyVoteForYou are managed. Once cutover completes,
`morph/provisioning`, the Vagrantfile and the Makefile ansible targets are
removed from this repository, which then retains application deployment
(Capistrano) and local docker-compose development only.

## Consequences

Infrastructure changes for morph happen in a different repository from the
application, with its own review flow. The genuinely morph-specific roles
(morph-app, docker-server, nginx-passenger, discourse, mitmproxy) are ported
there rather than kept here.
