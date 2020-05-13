#!/bin/bash

configure_dns() {

  if [ ! -z "$(ifconfig | grep "$IP_INTERNET_INFRA0")" ]
  then
    NEW_HOSTNAME="$HOSTNAME_INFRA0"
  elif [ ! -z "$(ifconfig | grep "$IP_INTERNET_COMPUTE00")" ]
  then
    NEW_HOSTNAME="$HOSTNAME_COMPUTE00"
  elif [ ! -z "$(ifconfig | grep "$IP_INTERNET_COMPUTE01")" ]
  then
    NEW_HOSTNAME="$HOSTNAME_COMPUTE01"
  elif [ ! -z "$(ifconfig | grep "$IP_INTERNET_COMPUTE02")" ]
  then
    NEW_HOSTNAME="$HOSTNAME_COMPUTE02"
  fi

  systemctl stop systemd-resolved
  systemctl disable systemd-resolved
  hostname "$NEW_HOSTNAME"
  sed -i -- 's/'$HOSTNAME'/'$NEW_HOSTNAME'/g' /etc/hosts
  rm -rf /etc/resolv.conf
  echo $'search openstack.ita
nameserver '$DNS_INTERNET > /etc/resolv.conf
}

configure_network() {

  apt update; apt install vim htop ethtool bridge-utils -y;
  apt autoremove netplan netplan.io nplan -y
  sed -i -- 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
  modprobe bonding

  if [ $(hostname) = "$HOSTNAME_INFRA0" ]
  then
    IP_INTERNET="$IP_INTERNET_INFRA0"
    IP_MGMT="$IP_MGMT_INFRA0"
    IP_TENANT="$IP_TENANT_INFRA0"
    IF_INTERNET="$IF_INTERNET_INFRA0"
    IF_MGMT="$IF_MGMT_INFRA0"
    IF_TENANT="$IF_TENANT_INFRA0"
  elif [ $(hostname) = "$HOSTNAME_COMPUTE00" ]
  then
    IP_INTERNET="$IP_INTERNET_COMPUTE00"
    IP_MGMT="$IP_MGMT_COMPUTE00"
    IP_TENANT="$IP_TENANT_COMPUTE00"
    IF_INTERNET="$IF_INTERNET_COMPUTE00"
    IF_MGMT="$IF_MGMT_COMPUTE00"
    IF_TENANT="$IF_TENANT_COMPUTE00"
  elif [ $(hostname) = "$HOSTNAME_COMPUTE01" ]
  then
    IP_INTERNET="$IP_INTERNET_COMPUTE01"
    IP_MGMT="$IP_MGMT_COMPUTE01"
    IP_TENANT="$IP_TENANT_COMPUTE01"
    IF_INTERNET="$IF_INTERNET_COMPUTE01"
    IF_MGMT="$IF_MGMT_COMPUTE01"
    IF_TENANT="$IF_TENANT_COMPUTE01"
  elif [ $(hostname) = "$HOSTNAME_COMPUTE02" ]
  then
    IP_INTERNET="$IP_INTERNET_COMPUTE02"
    IP_MGMT="$IP_MGMT_COMPUTE02"
    IP_TENANT="$IP_TENANT_COMPUTE02"
    IF_INTERNET="$IF_INTERNET_COMPUTE02"
    IF_MGMT="$IF_MGMT_COMPUTE02"
    IF_TENANT="$IF_TENANT_COMPUTE02"
  fi

  echo -e 'auto lo
iface lo inet loopback

auto '$IF_INTERNET' 
iface '$IF_INTERNET' inet manual
    bond-master '$BOND_INTERNET'
    bond-primary '$IF_INTERNET'

auto '$IF_MGMT' 
iface '$IF_MGMT' inet manual
    bond-master '$BOND_MGMT'
    bond-primary '$IF_MGMT'

auto '$IF_TENANT' 
iface '$IF_TENANT' inet manual
    bond-master '$BOND_TENANT'
    bond-primary '$IF_TENANT'

auto '$BOND_INTERNET' 
iface '$BOND_INTERNET' inet manual
    bond-slaves '$IF_INTERNET'
    bond-downdelay 200
    bond-miimon 100
    bond-mode 5
    bond-updelay 200
    bond-xmit_hash_policy layer3+4

auto '$BOND_MGMT'
iface '$BOND_MGMT' inet manual
    bond-slaves '$IF_MGMT'
    bond-downdelay 200
    bond-miimon 100
    bond-mode 5
    bond-updelay 200
    bond-xmit_hash_policy layer3+4

auto '$BOND_TENANT'
iface '$BOND_TENANT' inet manual
    bond-slaves '$IF_TENANT'
    bond-downdelay 200
    bond-miimon 100
    bond-mode 5
    bond-updelay 200
    bond-xmit_hash_policy layer3+4

auto '$BOND_INTERNET'.'$VLAN_TAG_INTERNET'
iface '$BOND_INTERNET'.'$VLAN_TAG_INTERNET' inet static
    vlan-raw-device '$BOND_INTERNET'
    address '$IP_INTERNET'
    netmask '$MASK_INTERNET'
    gateway '$GW_INTERNET'
    dns-nameservers '$DNS_INTERNET'

auto '$BOND_MGMT'.'$VLAN_TAG_MGMT'
iface '$BOND_MGMT'.'$VLAN_TAG_MGMT' inet static
    vlan-raw-device '$BOND_MGMT'
    address '$IP_MGMT'
    netmask '$MASK_MGMT'

auto '$BOND_TENANT'.'$VLAN_TAG_TENANT'
iface '$BOND_TENANT'.'$VLAN_TAG_TENANT' inet static
    vlan-raw-device '$BOND_TENANT'
    address '$IP_TENANT'
    netmask '$MASK_TENANT > /etc/network/interfaces
}

update_os() {
  apt update
  apt install debootstrap ifenslave ifenslave-2.6 lsof lvm2 chrony openssh-server sudo \
          tcpdump vlan python python3 python-pip python3-pip aptitude build-essential git \
          python-dev python3-dev sudo -y
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.utf8
  echo $'8021q' > /etc/modules
  echo $'8021q' > /etc/modules-load.d/openstack-ansible.conf
  service chrony restart
  timedatectl set-timezone America/Sao_Paulo
}

configure_ssh() {
  rm -rf /root/.ssh/* 2> /dev/null
  ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  echo -e 'Host *
  StrictHostKeyChecking no' > /root/.ssh/config
  chmod 400 /root/.ssh/config
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

source parameters.conf

HOSTNAME=$(hostname)

configure_dns;
configure_network;
update_os;
configure_ssh;

