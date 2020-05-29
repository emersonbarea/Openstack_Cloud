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

  apt update; apt install vim htop ethtool bridge-utils openvswitch-switch openvswitch-common -y;
  apt autoremove netplan netplan.io nplan -y
  sed -i -- 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
  modprobe bonding

  if [ $(hostname) = "$HOSTNAME_INFRA0" ]
  then
    IP_INTERNET="$IP_INTERNET_INFRA0"
    IP_MGMT="$IP_MGMT_INFRA0"
    IP_TENANT="$IP_TENANT_INFRA0"
    IP_STORAGE="$IP_STORAGE_INFRA0"
    IF0="$IF0_INFRA0"
    IF1="$IF1_INFRA0"
    IF2="$IF2_INFRA0"
    IF3="$IF3_INFRA0"
  elif [ $(hostname) = "$HOSTNAME_COMPUTE00" ]
  then
    IP_INTERNET="$IP_INTERNET_COMPUTE00"
    IP_MGMT="$IP_MGMT_COMPUTE00"
    IP_TENANT="$IP_TENANT_COMPUTE00"
    IP_STORAGE="$IP_STORAGE_COMPUTE00"
    IF0="$IF0_COMPUTE00"
    IF1="$IF1_COMPUTE00"
    IF2="$IF2_COMPUTE00"
    IF3="$IF3_COMPUTE00"
  elif [ $(hostname) = "$HOSTNAME_COMPUTE01" ]
  then
    IP_INTERNET="$IP_INTERNET_COMPUTE01"
    IP_MGMT="$IP_MGMT_COMPUTE01"
    IP_TENANT="$IP_TENANT_COMPUTE01"
    IP_STORAGE="$IP_STORAGE_COMPUTE01"
    IF0="$IF0_COMPUTE01"
    IF1="$IF1_COMPUTE01"
    IF2="$IF2_COMPUTE01"
    IF3="$IF3_COMPUTE01"
  elif [ $(hostname) = "$HOSTNAME_COMPUTE02" ]
  then
    IP_INTERNET="$IP_INTERNET_COMPUTE02"
    IP_MGMT="$IP_MGMT_COMPUTE02"
    IP_TENANT="$IP_TENANT_COMPUTE02"
    IP_STORAGE="$IP_STORAGE_COMPUTE02"
    IF0="$IF0_COMPUTE02"
    IF1="$IF1_COMPUTE02"
    IF2="$IF2_COMPUTE02"
    IF3="$IF3_COMPUTE02"
  fi

  echo -e 'auto lo
iface lo inet loopback

auto '$IF0' 
iface '$IF0' inet manual
    bond-master '$BOND'
    bond-primary '$IF0'

auto '$IF1' 
iface '$IF1' inet manual
    bond-master '$BOND'
    bond-primary '$IF1'

auto '$IF2' 
iface '$IF2' inet manual
    bond-master '$BOND'
    bond-primary '$IF2'

auto '$IF3'
iface '$IF3' inet manual
    bond-master '$BOND'
    bond-primary '$IF3'

auto '$BOND' 
iface '$BOND' inet static
    bond-slaves '$IF0' '$IF1' '$IF2' '$IF3'
    bond-downdelay 200
    bond-miimon 100
    bond-mode 802.3ad
    bond-updelay 200
    bond-xmit_hash_policy layer2
    address '$IP_INTERNET'
    netmask '$MASK_INTERNET'
    gateway '$GW_INTERNET'
    dns-nameservers '$DNS_INTERNET'

auto '$BOND'.'$VLAN_TAG_MGMT'
iface '$BOND'.'$VLAN_TAG_MGMT' inet manual
    vlan-raw-device '$BOND'

auto '$BOND'.'$VLAN_TAG_TENANT'
iface '$BOND'.'$VLAN_TAG_TENANT' inet manual
    vlan-raw-device '$BOND'

auto '$BOND'.'$VLAN_TAG_STORAGE'
iface '$BOND'.'$VLAN_TAG_STORAGE' inet manual
    vlan-raw-device '$BOND'

auto '$BOND'.'$VLAN_TAG_INTERNET_VM'
iface '$BOND'.'$VLAN_TAG_INTERNET_VM' inet manual
    vlan-raw-device '$BOND'
   
auto '$OVS_BRIDGE_MGMT'
iface '$OVS_BRIDGE_MGMT' inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports '$BOND'.'$VLAN_TAG_MGMT'
    address '$IP_MGMT'
    netmask '$MASK_MGMT'

auto '$OVS_BRIDGE_TENANT'
iface '$OVS_BRIDGE_TENANT' inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports '$BOND'.'$VLAN_TAG_TENANT' 
    address '$IP_TENANT'
    netmask '$MASK_TENANT'

auto '$OVS_BRIDGE_STORAGE'
iface '$OVS_BRIDGE_STORAGE' inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports '$BOND'.'$VLAN_TAG_STORAGE'
    address '$IP_STORAGE'
    netmask '$MASK_STORAGE > /etc/network/interfaces
}

update_os() {
  apt update
  apt install debootstrap ifenslave ifenslave-2.6 lsof lvm2 chrony openssh-server sudo \
          tcpdump vlan python python3 python-pip python3-pip aptitude build-essential git \
          python-dev python3-dev sudo apt-utils -y
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.utf8
  echo $'8021q' > /etc/modules
  echo $'8021q' > /etc/modules-load.d/openstack-ansible.conf
  service chrony restart
  timedatectl set-timezone America/Sao_Paulo
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
