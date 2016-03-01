#
# Cookbook Name:: apache
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#\  

case node['platform']
when 'debian', 'ubuntu'
  # do debian/ubuntu things
  execute "apt-get update" do
    command "apt-get update"
  end
  package 'apache2' do
  	action :install
  end
  service "apache2" do
 	  action [:enable, :start]
  end
when 'redhat', 'centos', 'fedora'
  # do redhat/centos/fedora things
  execute "flush" do
  	command "iptables --flush"
  	action :run
  end
  package 'httpd' do
	 action :install
  end
  service "httpd" do
	 action [:enable, :start]
  end
end
file '/var/www/index.html' do
  content '<html><h1>This is sample Bluemeric Demo</h1></html>'
  mode '0755'
end


