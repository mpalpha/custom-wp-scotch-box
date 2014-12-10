# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "scotch/box"
  config.vm.network "private_network", ip: "192.168.2.10"
  config.vm.network "forwarded_port", guest: 80, host: 25570
  config.vm.hostname = "scotch-wp-app"
  config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=666"]
  config.vm.provision :shell, :path => "bootstrap.sh"

end
