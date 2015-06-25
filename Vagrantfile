# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # local: A local machine that mimics a production deployment

  # All VMs are based on Ubuntu Precise 64 bit
  config.vm.box = "ubuntu"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.define "local" do |local|
    local.vm.network :private_network, ip: "192.168.11.2"
    local.vm.hostname = "dev.morph.io"
    local.vm.network :forwarded_port, guest: 22, host: 2200
    local.vm.network :forwarded_port, guest: 4443, host: 4443
    local.vm.synced_folder ".", "/vagrant", disabled: true

    local.vm.provider "virtualbox" do |v|
      v.memory = 2048
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
