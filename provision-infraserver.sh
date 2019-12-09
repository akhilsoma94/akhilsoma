#!/bin/bash

RUNUSER=`/bin/whoami`

if [ "$RUNUSER" != "root" ]; then
echo "you must be a root user"
exit
fi

#checking the network setup in vagrant
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd.service

#Disable the selinux
sed -i 's/SELINUX=enforcing/SELINUX=disable/' /etc/selinux/config

setenforce disable

#set the ip address in the host file
echo "192.168.10.50  infraserver" >> /etc/hosts
echo "192.168.10.60  infraclient" >> /etc/hosts

#stop and disable the firewalld
systemctl stop firewalld.service
systemctl disable firewalld.service

/sbin/reboot

sleep 10

#mount the minimal disc into the /mnt directory
mount -t iso9660 /dev/sr0 /mnt

#checking the createrepo is installed or not
rpm -q createrepo
if [ "$?" -ne 0 ]; then
  yum install -y createrepo
fi

#creating a directory localrepo in /
if [ ! -d "/localrepo" ]; then
  mkdir /localrepo
fi

#copy media to the created folder
cp -rv /mnt/* /localrepo/

#Backup repository folder
cp -r /etc/yum.repos.d /etc/yum.repos.d-bak

#Delete all online repository files
rm-rf /etc/yum.repos.d/*


#create locate repository file
echo "
[centos7]
name=centos7
baseurl=file:///localrepo/
enabled=1
gpgcheck=0
 " >> /etc/yum.repos.d/local.repo

#update the local repository
createrepo /localrepo/

#enable the local repository & clean
yum clean all

yum repolist all

#Test Local Repository
yum -y update

#checking the httpd package is available or not
rpm -q httpd
if [ "$?" -ne 0 ]; then
echo " package not available "
fi

#installing the httpd package
yum install -y httpd
if [ "$?" -ne 0 ]; then
cp /etc/yum.repos.d-bak/* /etc/yum.repos.d
yum install -y httpd
fi

#status and start httpd package
systemctl status httpd
systemctl start httpd
chkconfig httpd on


echo "
DocumentRoot "/localrepo"
     
<Directory "/localrepo">
AllowOverride None
Require all granted
</Directory>

<Directory "/localrepo/"
" >> /etc/httpd/conf/httpd.conf


rm -rf /etc/httpd/conf.d/welcome.comf
httpd -t

systemctl restart httpd

#
rpm -q wget
if [ "$?" -ne 0]; then
   yum install -y wget
fi

#moving the wget from home to localrepo/packages directory
cp wget-1.14-18.el7_6.1.x86_64 /localrepo/Packages/

#updating the repo-one
createrepo --update /localrepo/

