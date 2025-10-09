# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # local: A local machine that mimics a production deployment

  config.vm.box = "cloud-image/ubuntu-24.04"
  # This setting depends on installing the plugin https://github.com/sprotheroe/vagrant-disksize:
  # vagrant plugin install vagrant-disksize
  config.disksize.size = "20GB"

  config.vm.define "local" do |local|
    local.vm.network :private_network, ip: "192.168.56.2"
    local.vm.hostname = "dev.morph.io"
    local.hostsupdater.aliases = ["faye.dev.morph.io", "api.dev.morph.io", "help.dev.morph.io"]
    local.vm.network :forwarded_port, guest: 22, host: 2200
    local.vm.network :forwarded_port, guest: 4443, host: 4443
    # faye.dev.morph.io, dev.morph.io, api.dev.morph.io
    local.vm.network :forwarded_port, guest: 443, host: 8443
    # Use vagrant as both staging AND development!
    # local.vm.synced_folder ".", "/vagrant", disabled: true

    local.vm.provider "virtualbox" do |v|
      # Without elasticsearch we can run with 2GB of memory, but otherwise
      v.memory = 4096
    end

    local.vm.provision :ansible do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "provisioning/playbook.yml"
      ansible.verbose = "v"
      ansible.groups = {
        "development" => ["local"]
      }
      tags = ENV["TAGS"].to_s.gsub(/[^A-Z0-9_]+/i, ",").split(",").reject { |s| s.to_s == "" }
      if tags.any?
        puts "INFO: Only running TAGS: #{tags.inspect}"
        ansible.tags = tags
      end
      skip_tags = ENV["SKIP_TAGS"].to_s.gsub(/[^A-Z0-9_]+/i, ",").split(",").reject { |s| s.to_s == "" }
      if skip_tags.any?
        puts "INFO: Skipping TAGS: #{skip_tags.inspect}"
        ansible.skip_tags = skip_tags
      end
      verbose_flag = if ENV["ANSIBLE_VERBOSE"].to_s =~ /(v+)/
                       "-#{Regexp.last_match(1)}"
                     elsif ENV["ANSIBLE_VERBOSE"]
                       true
                     end
      if verbose_flag
        puts "INFO: Setting verbose: #{verbose_flag}"
        ansible.verbose = verbose_flag
      end
      start_at_task = "*#{ENV.fetch('START_AT_TASK', nil)}*".gsub(/[^A-Z0-9_]+/i, "*")
      if start_at_task != "*"
        puts "INFO: Starting at task matching: #{start_at_task}"
        ansible.start_at_task = start_at_task
      end
    end
  end
end
