# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # local: A local machine that mimics a production deployment

  # Annoyingly this box doesn't come with a disk big enough for what we need
  # to do here. So, you'll find it will run out of space when it comes to
  # installing discourse. If you want to avoid this you can manually resize
  # the disk image by following the instructions here:
  # http://tuhrig.de/resizing-vagrant-box-disk-space/
  #
  config.vm.box = "ubuntu/xenial64"
  config.disksize.size = '20GB'

  config.vm.define "local" do |local|
    local.vm.network :private_network, ip: "192.168.11.2"
    local.vm.hostname = "dev.morph.io"
    local.hostsupdater.aliases = ["faye.dev.morph.io", "api.dev.morph.io", "help.dev.morph.io"]
    local.vm.network :forwarded_port, guest: 22, host: 2200
    local.vm.network :forwarded_port, guest: 4443, host: 4443
    local.vm.synced_folder ".", "/vagrant", disabled: true

    local.vm.provider "virtualbox" do |v|
      # Without elasticsearch we can run with 2GB of memory, but otherwise
      v.memory = 4096
    end

    local.vm.provision :ansible do |ansible|
      ansible.playbook = "provisioning/playbook.yml"
      ansible.verbose = 'v'
      ansible.groups = {
        "development" => ["local"]
      }
    end
  end
end
