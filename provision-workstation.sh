#!/bin/bash

RUNUSER=`/bin/whoami`

if [ "$RUNUSER" != "root" ]; then
  echo "You MUST be a root user"
  exit
fi

sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd.service


sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
setenforce permissive


#seting date and time
timedatectl set-timezone "Asia/Kolkata"

#enable and start ntpdate service
systemctl enable ntpdate.service
systemctl start ntpdate.service


#'chefdk version details'

#chefdkrpm="chefdk-4.4.27-1.el7.x86_64.rpm"
chefdk_rpm="chefdk"
chefdk_rpm_version="4.4.27-1"
chefdk_rpm_os_version="el7"
chefdk_rpm_arch="x86_64"

chefdkrpm="$chefdk_rpm-$chefdk_rpm_version.$chefdk_rpm_os_version.$chefdk_rpm_arch.rpm"

#checking wget & ntp &unzip installed or not
wgetinfo=wget
ntpinfo=ntp
unzipinfo=unzip

rpm -q "$wgetinfo"
if [ "$?"  -ne 0 ]; then
  yum install -y wget
fi

rpm -q "$ntpinfo"
if [ "$?" -ne 0 ]; then
  yum install -y ntp
fi

rpm -q "unzipinfo"
if [ "$?" -ne 0 ]; then
   yum install -y unzip
fi

echo "192.168.10.20  chefserver" >> /etc/hosts
echo "192.168.10.30  workstation" >> /etc/hosts
echo "192.168.10.40  redhatweb01" >> /etc/hosts

# Stop and Disable firewall
systemctl stop firewalld.service
systemctl disable firewalld.service

sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
setenforce permissive

# user creation centos

/usr/bin/id centos
if [ $? -ne 0 ]; then
  echo 'create a user'
elif [$? -eq 0 ]; then
  echo 'user already exists'
  exit
fi

/sbin/useradd centos
if [ $? -ne 0 ]; then
  echo 'we have a serious problem in user creation'
fi

echo "redhat" | /usr/bin/passwd --stdin "centos"
if [ $? -ne 0 ]; then
  echo 'we have a serious problem in setting password'
fi

# passwd -f centos eq redhat123
echo 'passwd created successfully'

#Giving sudo permissions to user

usermod -a -G wheel centos

# su - centos

#echo {redhat} | sudo -S su - {centos}

echo 'starting provision: chefdk'

# check download dir, if not create it
if [ ! -d "chefdktools" ]; then
  mkdir chefdktools
  cp /vagrant/chefdk-4.4.27-1.el7.x86_64.rpm chefdktools
fi

cd chefdktools

#Downloading the chefdk package

if [ ! -f "$chefdkrpm" ]; then
  sudo wget -q "https://packages.chef.io/files/stable/chefdk/4.4.27/el/7/$chefdkrpm"
fi

#install packages, if not already installed

rpm -q "$chefdkrpm"

if [ "$?" -ne 0 ]; then
  sudo rpm -ivh "$chefdkrpm"
fi

#back to home directory
cd /home/centos

cp /vagrant/chef-starter.zip /home/centos
unzip /home/centos/chef-starter.zip -d /home/centos

#changing the ownership of the file
chown -R centos:centos /home/centos/chef-repo

#changing directory to chef-repo
cd /home/centos/chef-repo

sudo -u centos sh -c "cd /home/centos/chef-repo && knife ssl fetch"
sudo -u centos sh -c "cd /home/centos/chef-repo && knife ssl check"
sudo -u centos sh -c "cd /home/centos/chef-repo && knife user list"


sudo -u centos sh -c "cd /home/centos/chef-repo && knife bootstrap 192.168.10.40 -N redhatweb01 -U chefadmin -P chefadmin123 --use-sudo-password --sudo --yes"

