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

$public_ip = `wget http://ipinfo.io/ip -qO -`
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
# Create the database
########################################################################################################################
execute "create_database" do
    command "mysqladmin create vanilla"
end

########################################################################################################################
# Load the the database with some default data
########################################################################################################################
execute "load_database" do
    command "mysql -uroot vanilla < /tmp/bm_vanilla.sql"
    #only_if { !node.default['config']['mysql_database_load_file'].nil? && node.default['config']['mysql_database_load_file'] != "" }
end

########################################################################################################################
# Grant access to the database to the application user
########################################################################################################################
execute "grant_access" do
    command "mysql -uroot -e \"GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON vanilla.* TO 'vanilla'@'%' IDENTIFIED BY 'PassWord';\""
end


execute "bind_address" do
    command "sudo sed -e '/bind-address/s/^/#/g' -i /etc/mysql/my.cnf"
end

########################################################################################################################
# Reload the privileges.
########################################################################################################################
execute "flush_priviliges" do
    command "mysqladmin flush-privileges"
end

######################################################################################################################################################
# Open up Port 3306 (MySQL).
######################################################################################################################################################
execute "iptables -I INPUT -p tcp --dport 3306 -j ACCEPT"
execute "iptables-save"

####################################################################################
## Restart mysql service
####################################################################################
execute "mysql_service_restart" do
    command "sudo /etc/init.d/mysql restart"
end





