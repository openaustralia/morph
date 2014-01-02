Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision :ansible do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
    #ansible.verbose = 'vvv'
  end
end
