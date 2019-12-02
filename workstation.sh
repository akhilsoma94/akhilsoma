#!/bin/bash

#https://packages.chef.io/files/stable/chefdk/4.4.27/el/7/chefdk-4.4.27-1.el7.x86_64.rpm
RUNUSER=`/bin/whoami`

# chefdkrpm="chefdk-4.4.27-1.el7.x86_64.rpm"
chefdk_rpm="chefdk"
chefdk_rpm_version="4.4.27-1"
chefdk_rpm_os_version="el7"
chefdk_rpm_arch="x86_64"

chefdkrpm="$chefdk_rpm-$chefdk_rpm_version.$chefdk_rpm_os_version.$chefdk_rpm_arch.rpm"

#checking wget installed or not
wgetinfo=wget-1.14-18.el7_6.1.x86_64
ntpinfo=ntp.x86_64 0:4.2.6p5-29.el7.centos

if [ "$RUNUSER" != "root" ]; then
  echo "You MUST be a root user"
  exit
fi

rpm -q "$wgetinfo"
if [ "$?"  -ne 0 ]; then
  yum install -y wget
fi

rpm -q "$ntpinfo"
if [ "$?" -ne 0 ]; then
  yum install -y ntp
fi

#seting date and time
timedatectl set-timezone "Asia/Kolkata"

#enable and start ntpdate service
systemctl enable ntpdate.service
systemctl start ntpdate.service

echo "192.168.10.20  chefserver" >> /etc/hosts
echo "192.168.10.30  workstation" >> /etc/hosts
echo "192.168.10.40  redhatweb01" >> /etc/hosts

# Stop and Disable firewall
systemctl stop firewalld.service
systemctl disable firewalld.service

setenforce permissive

# user creation akhil

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

echo "centos123" | /usr/bin/passwd --stdin "centos"
if [ $? -ne 0 ]; then
  echo 'we have a serious problem in setting password'
fi

# passwd -f centos eq centos123
echo 'passwd created successfully'


echo 'starting provision: chefdk'

# check download dir, if not create it
if [ ! -d "chefdktools" ]; then
  mkdir chefdktools
fi

cd chefdktools

#Downloading the chefdk package

if [ ! -f "$chefdkrpm" ]; then
  wget -q "https://packages.chef.io/files/stable/chefdk/4.4.27/el/7/$chefdkrpm"
fi

#install packages, if not already installed
rpm -q "$chefdkrpm"

if [ "$?" -ne 0 ]; then
  rpm -ivh "$chefdkrpm"
fi

