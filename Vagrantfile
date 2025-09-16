# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # local: A local machine that mimics a production deployment

  config.vm.box = "ubuntu/xenial64"
  # This setting depends on installing the plugin https://github.com/sprotheroe/vagrant-disksize:
  # vagrant plugin install vagrant-disksize
  config.disksize.size = "20GB"

  config.vm.define "local" do |local|
    local.vm.network :private_network, ip: "192.168.56.2"
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
      ansible.verbose = "v"
      ansible.groups = {
        "development" => ["local"]
      }
      raw_args = []
      raw_args << "--tags=#{ENV['TAGS']}" if ENV["TAGS"]
      if ENV["START_AT_TASK"]
        sat = "*#{ENV['START_AT_TASK']}*".gsub(" ", "*")
        raw_args << "--start-at-task=#{sat}"
      end
      ansible.raw_arguments = raw_args
    end
  end
end
