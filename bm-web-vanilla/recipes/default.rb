#
# Cookbook Name:: bm-web-vanilla
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
###############################################################################
# Search for DB server for the stack being launched and get it's IP address
###############################################################################

###############################################################################
# Important this match relies on the MySQL server ending in "vanilla-web-vm-*"
###############################################################################

log "*** The Vanilla Web Application Server node name is #{node.name} ***"

# Get the stack name from the node name
string="(^.+)-vanilla-web$"
match_result=node.name.match(string)
if (match_result.captures[0].nil?)
    Chef::Application.fatal!("*** Unable to locate the vanilla Web Server using string #{string}! ***")
end   

stack_name=match_result.captures[0]
log "*** The stack name is #{stack_name} ***"

# Set the config attribute sitename with the stack name
node.default['config']['sitename'] = "'#{stack_name}'"

###############################################################################
# Important this search relies on the MySQL server ending in "vanilla-mysql-vm*"
###############################################################################
log "*** Searching the Chef server for the MySQL server\'s IP Address using #{stack_name}-vanilla-mysql-vm* as the node name. ***"

mysql_ip_address = ""
mysql_hostname = ""

retry_counter = 1;

# This search will check for the MySQL Server's IP address up to 20 times, sleeping 30 seconds between intervals
while ((mysql_ip_address.nil? || mysql_ip_address == "") && retry_counter < 20)
 
  db_vm = search(:node , "name:#{stack_name}-vanilla-db\*")
  db_vm.each do |db_node|

    mysql_ip_address = db_node["ipaddress"]
    mysql_hostname   = db_node["hostname"]

    break if !mysql_ip_address.nil? && mysql_ip_address != ""

  end

  break if !mysql_ip_address.nil? && mysql_ip_address != ""

  log "*** Chef search returned a \"blank\" value for the MySQL server\'s IP address, sleeping for 30 seconds.... ***"
  sleep(30)
  retry_counter += 1

end  

if mysql_ip_address.nil? || mysql_ip_address == ""
  Chef::Application.fatal!("*** Unable to get the IP address for the MySQL node! ***")
else
  log "*** The MySQL database server #{mysql_hostname } has IP address #{mysql_ip_address} ***"
  node.default['config']['bm_mysqlhost'] =  "'#{mysql_ip_address}'"
end 

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
      user "root"
      cwd "#{app_root}"
      code <<-EOF
      unzip #{app_root}/vanilla.zip
      rm -rf #{app_root}/vanilla.zip index.html
      EOF
end

#######################################################################################################################
# Make the apache user the owner of all of the files in the virtual host site directory
#######################################################################################################################
bash "give_the access permission" do
      user "root"
      cwd "#{app_root}"
      code <<-EOF
	    chmod -R 777 /var/www/conf
	    chmod -R 777 /var/www/uploads
	    chmod -R 777 /var/www/cache
      EOF
end

###############################################################################
# Update the vanilla config.php file and notify apache2 to restart
###############################################################################
template "#{app_root}/conf/config.php" do
    source "config.php.erb"
    owner "root"
    group "root"
    mode "0644"
    action :create
end

###############################################################################
# Restart the vanilla apache 2 web server
###############################################################################
execute "restart apache service" do
   command "/etc/init.d/apache2 restart"
end
 


