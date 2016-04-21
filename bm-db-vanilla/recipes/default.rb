#
# Cookbook Name:: bm-db-vanilla
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

########################################################
# Update database Ip in databags
########################################################
#To create a data bag from a recipe:
########################################################
#users = Chef::DataBag.new
#users.name('sankars')
#users.create
########################################################
#To create a data bag item from a recipe:
########################################################
#sam = {
#  'id' => 'multi_info',
#  'Full Name' => 'sankars',
#  'db_hostname' => 'db_host',
#  'web_hostname' => 'web_host',
#  'db_ip' => 'db_ip',
#  'web_ip' => 'web_ip'
#}
#databag_item = Chef::DataBagItem.new
#databag_item.data_bag('sankars')
#databag_item.raw_data = sam
#databag_item.save
#########################################################

$public_ip = `wget http://ipecho.net/plain -O - -q ; echo`
#puts "#$public_ip"
# #To edit the contents of a data bag item from a recipe:
database_ip = data_bag_item('sankars', 'multi_info')
database_ip['db_ip'] = "#$public_ip"
database_ip['db_hostname'] = node['hostname']
database_ip.save

#######################################################################################################################
# Main Entry of the Recipe
#######################################################################################################################

log "*** This virtual machine is running the platform: " + node.platform + 
    ", family: " + node.platform_family + ", version: " + node.platform_version  + " ***"

include_recipe "apt"

########################################################################################################################
# Install and setup the MySQL Server
########################################################################################################################
%w{mysql-server mysql-client }.each do |pkg|
   apt_package pkg do
      action :install
   end
end

########################################################################################################################
# Get the MySQL database initial sql file
########################################################################################################################
template "/tmp/bm_vanilla.sql" do
    source "bm_vanilla.sql"
    #owner "root"
    #group "root"
    mode "0644"
    action :create
end

########################################################################################################################
# Configure the MySQL server and database
########################################################################################################################
log "*** Setting up the application user and database. ***"

########################################################################################################################
#
########################################################################################################################
script "database_load" do
  interpreter "bash"
  #user "root"
  cwd "/tmp"
  code <<-EOF
		mysqladmin create vanilla
		mysql -uroot vanilla < /tmp/bm_vanilla.sql
		mysql -uroot -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON vanilla.* TO 'vanilla'@'%' IDENTIFIED BY 'PassWord';"
		sudo sed -e '/bind-address/s/^/#/g' -i /etc/mysql/my.cnf
		mysqladmin flush-privileges
		iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
		iptables-save
		sudo /etc/init.d/mysql restart
	EOF
end





