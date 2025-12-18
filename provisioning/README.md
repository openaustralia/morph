Infrastructure as Code Development Environment
----------------------------------------------

### Requirements

Vagrant is used with the virtualbox provider to provide a local staging environment to develop
the ansible playbooks and roles used to provision the servers.

Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads) as a provider

Install [Vagrant](https://developer.hashicorp.com/vagrant/install)

Install a Tool version manager, for example [mise](https://mise.jdx.dev/getting-started.html) to manage tool versions

Install python using your tool manager: `mise install python`

Check `python --version` matches the contents of `.python-version`

Install Ansible using `pip install -r provisioning/requirements.txt`

Install ansible roles as per the comment on `provisioning/requirements.yml` - note these roles are ignored (as per `.gitignore`)
and are thus **not** committed to the git repo
```
cd provisioning 
ansible-galaxy install -r requirements.yml -p roles
```

If you are using `mise` then ensure the idomatic version files for ruby (`.ruby-version`) and python (`.python-version`) are enabled.
Check `~/.config/mise/config.toml` contains:
```
[settings]
idiomatic_version_file_enable_tools = ["ruby","python"]
```

Ensure you are running the python version specified in `.python-version` using `python --version`

Install the required ansbile version using pip:
```bash
pip install -r provisioning/requirements.txt
```

Checkout the infrastructure repo as a sibling directory and generate ssl certificates as per its README.md.
This will move a self signed ssl certificate into this project for its use in development.

### Ansible Vault

We're using [Ansible Vault](https://docs.ansible.com/ansible/2.4/vault.html) to encrypt certain files, like the private key for the SSL certificate.

To make this work you will need to put the password in a file at `../.infrastructure_ansible_vault_pass.txt`.
This is the same password as used in the [openaustralia/infrastructure](https://github.com/openaustralia/infrastructure) GitHub repository.

## Restarting Discourse

Discourse runs in a container and should usually be restarted automatically by docker.

However, if the container goes away for some reason, it can be restarted:

```
root@morph:/var/discourse# ./launcher rebuild app
```

This will pull down the latest docker image, rebuild, and restart the container.

## Production devops development

> This method defaults to creating a 4Gb VirtualBox VM, which can strain an 8Gb Mac.
> We suggest tweaking the Vagrantfile to restrict ram usage to 2Gb at first, or using a machine with at least 12Gb ram.

Install [Vagrant](http://www.vagrantup.com/), [VirtualBox](https://www.virtualbox.org) and [Ansible](http://www.ansible.com/).

Install a couple of Vagrant plugins: `vagrant plugin install vagrant-hostsupdater vagrant-disksize vagrant-vbguest`

Install a Ruby Version Manager, for example (from latest to oldest):
- [mise](https://mise.jdx.dev/) - modern, polyglot and fast (includes language installer)
- [chruby](https://github.com/postmodern/chruby) and [ruby-install](https://github.com/postmodern/ruby-install) - a lightweight alternative
- [rbenv](https://github.com/rbenv/rbenv) and [ruby-build](https://github.com/rbenv/ruby-build#readme) - the leader between 2015 and 2020
- [rvm](https://rvm.io/) - used on production and staging, the old faithful and well known ruby version manager

If on Ubuntu, install libreadline-dev: `sudo apt install libreadline-dev libsqlite3-dev`

Install the required ruby version: `rbenv install`

Install capistrano: `gem install capistrano`

Run `make roles` to install some required ansible roles.

Run `vagrant up local`. This will build and provision a box that looks and acts like production at `dev.morph.io`.

## Production devops development

> This method defaults to creating a 4Gb VirtualBox VM, which can strain an 8Gb Mac.
> We suggest tweaking the Vagrantfile to restrict ram usage to 2Gb at first, or using a machine with at least 12Gb ram.

Install [Vagrant](http://www.vagrantup.com/), [VirtualBox](https://www.virtualbox.org) and [Ansible](http://www.ansible.com/).

Install a couple of Vagrant plugins: `vagrant plugin install vagrant-hostsupdater vagrant-disksize`

Install a Ruby Version Manager, for example (from latest to oldest):
- [mise](https://mise.jdx.dev/) - modern, polyglot and fast (includes language installer)
- [chruby](https://github.com/postmodern/chruby) and [ruby-install](https://github.com/postmodern/ruby-install) - a lightweight alternative
- [rbenv](https://github.com/rbenv/rbenv) and [ruby-build](https://github.com/rbenv/ruby-build#readme) - the leader between 2015 and 2020
- [rvm](https://rvm.io/) - used on production and staging, the old faithful and well known ruby version manager

If on Ubuntu, install libreadline-dev: `sudo apt install libreadline-dev libsqlite3-dev`

Install the required ruby version: `rbenv install`

Install capistrano: `gem install capistrano`

Run `make roles` to install some required ansible roles.

Run `vagrant up local`. This will build and provision a box that looks and acts like production at `dev.morph.io`.

Once the box is created and provisioned, deploy the application to your Vagrant box:

    cap local deploy

Now visit https://dev.morph.io/

## Production provisioning

When you've changed the Ansible playbooks to modify the infrastructure you'll want to run:

    make ansible

## SSL certificates

We're using Let's Encrypt for SSL certificates. It's not 100% automated.
On a completely fresh install (with a new domain) as root:
```
certbot --nginx certonly -m contact@oaf.org.au --agree-tos
```

It should show something like this:
```
Which names would you like to activate HTTPS for?
-------------------------------------------------------------------------------
1: morph.io
2: api.morph.io
3: faye.morph.io
4: help.morph.io
```

Leave your answer your blank which will install the certificate for all of them

### Installing certificates for local vagrant VM

    vagrant ssh

    sudo certbot certonly --manual -d dev.morph.io --preferred-challenges dns -d api.dev.morph.io -d faye.dev.morph.io -d help.dev.morph.io

You will need admin permission for the morph.io domain to add TXT entries for

* _acme-challenge.api.dev.morph.io
* _acme-challenge.dev.morph.io
* _acme-challenge.faye.dev.morph.io
* _acme-challenge.help.dev.morph.io

### Scraper<->mitmdump SSL

Scrapers talk out to the internet by being routed through the mitmdump2
proxy container. The default container you'll get on a devops install
has no SSL certificates. This makes it easy for traffic to get out,
but means we can't replicate some problems that occur when the SSL
validation fails.

To work around this, you'll have to rebuild the mitmdump container. Look in `/var/www/current/docker_images/morph-mitmdump`;
there's a `Makefile` that will aid in building the new image.

Once that's done, you'll need to build a new version of the `openaustralia/buildstep`:

```bash
cd
git clone https://github.com/openaustralia/buildstep.git`
cd buildstep
cp /var/www/current/docker_images/morph-mitmdump/mitmproxy/mitmproxy-ca-cert.pem .
ln -s Dockerfile.heroku-24  Dockerfile
docker image build -t openaustralia/buildstep:latest .
```

You should now be able to see in `docker image list --all` that your new image is ready.
The next time you run a scraper it will be rebuilt using the new buildstep image.
