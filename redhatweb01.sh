#!/bin/bash

RUNUSER=`/bin/whoami`

if [ "$RUNUSER" != "root" ]; then
  echo "You MUST be a root user"
  exit
fi

#checking wget installed or not
wgetinfo=wget-1.14-18.el7_6.1.x86_64
ntpinfo=ntp.x86_64 0:4.2.6p5-29.el7.centos

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


/usr/bin/id chefadmin
if [ $? -ne 0 ]; then
  echo 'create a user'
elif [$? -eq 0 ]; then
  echo 'user already exists'
  exit
fi

/sbin/useradd chefadmin
if [ $? -ne 0 ]; then
  echo 'we have a serious problem in user creation'
fi

echo "chefadmin123" | /usr/bin/passwd --stdin "chefadmin"
if [ $? -ne 0 ]; then
  echo 'we have a serious problem in setting password'
fi

usermod -a -G wheel chefadmin

echo 'passwd created successfully'
