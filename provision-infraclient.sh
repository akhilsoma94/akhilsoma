#!/bin/bash

RUNUSER=`/bin/whoami`

if [ "$RUNUSER" != "root" ]; then
echo "you must be a root user"
exit
fi

#restarting network in sshd
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd.service

#disable the selinux
sed -i 's/SELINUX=enforcing/SELINUX=disable/' /etc/selinux/config

setenforce disable

#setting the ip address in localhost
echo "192.168.10.50  infraserver" >> /etc/hosts
echo "192.168.10.60  infraclient" >> /etc/hosts

#systemctl stop firewalld.service
#systemctl disable firewalld.service

#Backup the current repository folder
cp -r /etc/yum.repos.d /etc/yum.repos.d-bak

#remove all repository files.
rm -rf /etc/yum.repos.d/*

#creating a localrepo
echo " 
      [localrepo]
      name=Centos7 Repository
      baseurl=http://192.168.10.50/
      gpgcheck=0
      enabled=1
     " >> /etc/yum.repos.d/localrepo.repo

#list the repository
yum repolist

#clean the yum cache
yum clean all

#update the yum configuration
yum update
