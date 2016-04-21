#
# Cookbook Name:: bm-web-vanilla
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
# #To edit the contents of a data bag item from a recipe:
database_ip = data_bag_item('sankars', 'multi_info')
database_ip['web_ip'] = "#$public_ip"
database_ip['web_hostname'] = node['hostname']
database_ip.save

###############################################################################
# Search for DB server for the stack being launched and get it's IP address
###############################################################################
data = data_bag_item('sankars', 'multi_info')
db_ip = data['db_ip']
log "Database IP => #{db_ip}"
node.default['config']['bm_mysqlhost'] =  "'#{db_ip}'"
#######################################################################################################################
# Update the repository up to date
#######################################################################################################################
execute "Update the repository" do
   command "apt-get update"
end

#######################################################################################################################
# Main Entry of the Recipe
#######################################################################################################################

log "*** This virtual machine is running the platform: " + node.platform + 
    ", family: " + node.platform_family + ", version: " + node.platform_version  + " ***"

include_recipe "apt"

#######################################################################################################################
# update the dependency packages
#######################################################################################################################
%w{apache2 mysql-client php5 php5-mysql php5-gd sendmail unzip}.each do |pkg|
   apt_package pkg do
      action :install
   end
end

#######################################################################################################################
# Get the Apache Application root
#######################################################################################################################
app_root = "/var/www"

###############################################################################
# Download the Joomla installation code from the JoomlaCode site.
###############################################################################
remote_file "#{app_root}/vanilla.zip" do
    source "http://cdn.vanillaforums.com/www.vanillaforums.org/addons/I73N851HNLPN.zip"
    mode "0755"
    action :create
    not_if {File.exists?("#{app_root}/vanilla.zip")}
end

###############################################################################
# Extract the vanilla code
###############################################################################
bash "unpack_vanilla" do
      #user "root"
      cwd "#{app_root}"
      code <<-EOF
      unzip #{app_root}/vanilla.zip
      rm -rf #{app_root}/vanilla.zip index.html
      EOF
end

###############################################################################
# Update the vanilla config.php file and notify apache2 to restart
###############################################################################
template "#{app_root}/conf/config.php" do
    source "config.php.erb"
    #owner "root"
    #group "root"
    mode "0644"
    action :create
end
#######################################################################################################################
# Make the apache user the owner of all of the files in the virtual host site directory
#######################################################################################################################
bash "give_the access permission" do
      #user "root"
      cwd "#{app_root}"
      code <<-EOF
      chmod -R 777 /var/www/conf
      chmod -R 777 /var/www/uploads
      chmod -R 777 /var/www/cache
      EOF
end
###############################################################################
# Restart the vanilla apache 2 web server
###############################################################################
execute "restart apache service" do
   command "/etc/init.d/apache2 restart"
end
 


