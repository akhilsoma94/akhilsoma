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

#checking wget installed or not
wgetinfo=wget
ntpinfo=ntp

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
