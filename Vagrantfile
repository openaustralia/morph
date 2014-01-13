# -*- mode: ruby -*-
# vi: set ft=ruby :

# A script to upgrade from the 12.04 kernel to the raring backport kernel (3.8)
# and install docker.
$script = <<SCRIPT
# The username to add to the docker group will be passed as the first argument
# to the script.  If nothing is passed, default to "vagrant".
user="$1"
if [ -z "$user" ]; then
    user=vagrant
fi

# Adding an apt gpg key is idempotent.
wget -q -O - https://get.docker.io/gpg | apt-key add -

# Creating the docker.list file is idempotent, but it may overrite desired
# settings if it already exists.  This could be solved with md5sum but it
# doesn't seem worth it.
echo 'deb http://get.docker.io/ubuntu docker main' > \
    /etc/apt/sources.list.d/docker.list

# Update remote package metadata.  'apt-get update' is idempotent.
apt-get update -q

# Install docker.  'apt-get install' is idempotent.
apt-get install -q -y lxc-docker

usermod -a -G docker "$user"

tmp=`mktemp -q` && {
    # Only install the backport kernel, don't bother upgrade if the backport is
    # already installed.  We want parse the output of apt so we need to save it
    # with 'tee'.  NOTE: The installation of the kernel will trigger dkms to
    # install vboxguest if needed.
    apt-get install -q -y --no-upgrade linux-image-generic-lts-raring | \
        tee "$tmp"

    # Parse the number of installed packages from the output
    NUM_INST=`awk '$2 == "upgraded," && $4 == "newly" { print $3 }' "$tmp"`
    rm "$tmp"
}

# Make docker listen to TCP rather than a local socket (which is the default)
sed -i "s/DOCKER_OPTS=.*$/DOCKER_OPTS='-H 0.0.0.0:4243'/" /etc/init/docker.conf
service docker restart

# If the number of installed packages is greater than 0, we want to reboot (the
# backport kernel was installed but is not running).
if [ "$NUM_INST" -gt 0 ];
then
    echo "Rebooting down to activate new kernel."
    echo "/vagrant will not be mounted.  Use 'vagrant halt' followed by"
    echo "'vagrant up' to ensure /vagrant is mounted."
    shutdown -r now
fi
SCRIPT

# We need to install the virtualbox guest additions *before* we do the normal
# docker installation.  As such this script is prepended to the common docker
# install script above.  This allows the install of the backport kernel to
# trigger dkms to build the virtualbox guest module install.
$vbox_script = <<VBOX_SCRIPT + $script
# Install the VirtualBox guest additions if they aren't already installed.
if [ ! -d /opt/VBoxGuestAdditions-4.3.4/ ]; then
    # Update remote package metadata.  'apt-get update' is idempotent.
    apt-get update -q

    # Kernel Headers and dkms are required to build the vbox guest kernel
    # modules.
    apt-get install -q -y linux-headers-generic-lts-raring dkms

    echo 'Downloading VBox Guest Additions...'
    wget -cq http://dlc.sun.com.edgesuite.net/virtualbox/4.3.4/VBoxGuestAdditions_4.3.4.iso
    echo "f120793fa35050a8280eacf9c930cf8d9b88795161520f6515c0cc5edda2fe8a  VBoxGuestAdditions_4.3.4.iso" | sha256sum --check || exit 1

    mount -o loop,ro /home/vagrant/VBoxGuestAdditions_4.3.4.iso /mnt
    /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
fi
VBOX_SCRIPT


Vagrant.configure("2") do |config|
  # Note that this is a configuration for two different VMs
  # server: A deployed server
  # dev: A VM that has docker on it - used for development on OS X

  # Both VMs are based on Ubuntu Precise 64 bit
  config.vm.box = "ubuntu"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.define "production" do |production|
    production.vm.synced_folder ".", "/vagrant", disabled: true

    production.vm.provision :ansible do |ansible|
      ansible.playbook = "provisioning/playbook.yml"
      #ansible.verbose = 'vvv'
    end

    production.vm.provider :digital_ocean do |provider, override|
      override.ssh.private_key_path = '~/.ssh/id_rsa'
      override.vm.box = 'digital_ocean'
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"

      provider.image = "Ubuntu 12.04.3 x64"
      provider.size = "1GB"
      provider.client_id = ENV['DIGITAL_OCEAN_CLIENT_ID']
      provider.api_key = ENV['DIGITAL_OCEAN_API_KEY']
    end
  end

  config.vm.define "local" do |local|
    local.vm.network :forwarded_port, guest: 80, host: 8000
    local.vm.network :forwarded_port, guest: 22, host: 2200
    local.vm.synced_folder ".", "/vagrant", disabled: true

    local.vm.provision :ansible do |ansible|
      ansible.playbook = "provisioning/playbook.yml"
      ansible.extra_vars = { server_name: "dev.morph.io", env_file: ".env.local"}
      #ansible.verbose = 'vvv'
    end
  end

  config.vm.define "dev" do |dev|
    dev.ssh.forward_agent = true
    dev.vm.network :forwarded_port, guest: 4243, host: 4243

    dev.vm.synced_folder ".", "/vagrant", owner: 4243, group: 4243
    # Also creating another directory so that we don't run into permission problems with just using
    # the source code from the VM
    dev.vm.synced_folder ".", "/source"

    dev.vm.provider :virtualbox do |vb, override|
      override.vm.provision :shell, :inline => $vbox_script
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
  end

end
