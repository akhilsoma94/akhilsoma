#!/bin/bash


sed -i 's/SELINUX=Enforcing/SELINUX=Permissive/' /etc/selinux/config

setenforce Permissive


timedatectl set-timezone "Asia/Kolkata"


yum -y install ntp

systemctl start ntpdate

RUNUSER=`/bin/whoami`

# serverrpm="chef-server-core-13.0.17-1.el7.x86_64.rpm"
server_rpm="chef-server-core"
server_rpm_version="13.0.17-1"
server_os_version="el7"
server_arch="x86_64"

serverrpm="$server_rpm-$server_rpm_version.$server_os_version.$server_arch.rpm"

# managerpm="chef-manage-2.5.15-1.el7.x86_64.rpm"
manage_rpm="chef-manage"
manage_rpm_version="2.5.15-1"
manage_os_version="el7"
manage_arch="x86_64"

managerpm="$manage_rpm-$manage_rpm_version.$manage_os_version.$manage_arch.rpm"

if [ "$RUNUSER" != "root" ]; then
  echo "You MUST be a root user"
  exit
fi

echo "192.168.10.20  chefserver" >> /etc/hosts
echo "192.168.10.30  workstation" >> /etc/hosts
echo "192.168.10.40  redhatweb01" >> /etc/hosts


# Stop and Disable firewall
systemctl stop firewalld.service
systemctl disable firewalld.service

echo 'starting provision: chefserver'

rpm -q wget
if [ "$?" -ne 0 ]; then
  yum install -y wget
fi

# check download dir, if not create it
if [ ! -d "cheftools" ]; then
  mkdir cheftools
  cp /vagrant/*.rpm cheftools
fi

cd cheftools

# Download package, if not already downloaded URL: https://packages.chef.io/files/stable/chef-server/13.0.17/el/7/chef-server-core-13.0.17-1.el7.x86_64.rpm


if [ ! -f "$serverrpm" ]; then
   wget -q "https://packages.chef.io/files/stable/chef-server/13.0.17/el/7/$serverrpm"
fi

if [ ! -f "$managerpm" ]; then
  wget -q "https://packages.chef.io/files/stable/chef-manage/2.5.15/el/7/$managerpm"
fi

# Install packages, if not already installed

rpm -q "$serverrpm"

if [ "$?" -ne 0 ]; then
  rpm -ivh "$serverrpm"
fi

rpm -q "$managerpm"

if [ "$?" -ne 0 ]; then
  rpm -ivh $managerpm
fi

echo 'Installing chef server & manage'

# Accept license agreement here

if [ ! -d "/etc/chef/accepted_licenses" ]; then
  mkdir -p /etc/chef/accepted_licenses
fi

if [ ! -f "/etc/chef/accepted_licenses/chef_infra_server" ]; then
  touch /etc/chef/accepted_licenses/chef_infra_server
fi

if [ ! -f "/etc/chef/accepted_licenses/chef_infra_client" ]; then
    touch /etc/chef/accepted_licenses/chef_infra_client
fi

if [ ! -f "/etc/chef/accepted_licenses/inspec" ]; then
  touch /etc/chef/accepted_licenses/inspec
fi


# Reconfigure Chef Server, only at first time

sleep 10
chef-server-ctl reconfigure

# Reconfigure Chef Manage, only at first time

chef-manage-ctl reconfigure --accept-license

#echo 'reconfigured successfully'
#chef-server-ctl status
#
#if [ ! -d "/var/opt/chef-backup" ]; then
#  mkdir -p "/var/opt/chef-backup"
#fi
#
#cp /vagrant/chef-backup-2019-12-02-17-22-40.tgz /var/opt/chef-backup
#chef-server-ctl restore /var/opt/chef-backup/chef-backup-2019-12-02-17-22-40.tgz
#
#chef-server-ctl reconfigure
#chef-manage-ctl reconfigure
#
##cp /c/Users/Akhil/vagrant/chef-backup-2019-12-02-17-22-40.tgz /var/opt/chef-backup
#chef-server-ctl restore /var/opt/chef-backup/chef-backup-2019-12-02-17-22-40.tgz

# creating a username and organisation
username="centos"
firstname="centos"
lastname="centos"
email="centos@gmail.com"
passwd="centos123"

orgname=redhat
orgfullname='redhat pvt ltd'

echo 'creating a user $username'

chef-server-ctl user-show $username
if [ "$?" -ne 0 ]; then
  chef-server-ctl user-create $username $firstname $lastname $email $passwd -f $username.pem
else
 echo "The chef user $username already exists"
fi

chef-server-ctl org-show $orgname
if [ "$?" -ne 0 ]; then
 chef-server-ctl org-create $orgname $orgfullname -a $username -f $orgname-validator.pem
else
 echo "The chef organization $orgname already exists"
fi
# restore from chefserver

