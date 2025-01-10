#!/bin/bash

yum install epel-release -y 
yum install perl -y
tar -zxvf mlnx-en-23.04-1.1.3.0-rhel8.5-x86_64.tgz  
cd mlnx-en-23.04-1.1.3.0-rhel8.5-x86_64
sed -i 's/$releasever/8.7/g' /etc/yum.repos.d/veos.repo
yum install -y python36 gcc gdb-headless autoconf rpm-build automake kernel-devel-4.18.0-425.19.2.el8.x86_64 make lsof patch python36-devel kernel-rpm-macros createrepo elfutils-libelf-devel ipmitool
./install --dpdk --upstream-libs --distro rhel8.5 --add-kernel-support
