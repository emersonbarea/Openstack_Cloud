#!/bin/bash

configure_dns() {
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
    hostname "$HOSTNAME_SW_TENANT"
    sed -i -- 's/'$HOSTNAME'/'$HOSTNAME_SW_TENANT'/g' /etc/hosts
    rm -rf /etc/resolv.conf
    echo $'search openstack.ita
nameserver '$DNS_INTERNET > /etc/resolv.conf
}

update_SO() {
    apt update
    apt upgrade -y
    apt -f install -y
    apt autoremove -y
    apt install vim htop ethtool dpdk sysfsutils openvswitch-switch-dpdk python-pip ifupdown whois vlan -y
    pip install ryu tinyrpc==0.8
    timedatectl set-timezone America/Sao_Paulo
}

configure_network() {
    apt autoremove netplan netplan.io nplan -y
    sed -i -- 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
    echo $'auto lo
iface lo inet loopback

allow-hotplug '$IF_INTERNET_SW' 
iface '$IF_INTERNET_SW' inet manual

allow-hotplug '$OVS_BRIDGE_TENANT'
iface '$OVS_BRIDGE_TENANT' inet manual

allow-hotplug '$VLAN_IF_TENANT'
iface '$VLAN_IF_TENANT' inet manual

auto '$IF_INTERNET_SW'.'$VLAN_TAG_INTERNET'
iface '$IF_INTERNET_SW'.'$VLAN_TAG_INTERNET' inet static
    vlan-raw-device '$IF_INTERNET_SW'
    address '$IP_INTERNET_SW_TENANT'
    netmask '$MASK_INTERNET'
    gateway '$GW_INTERNET'
    dns-nameservers '$DNS_INTERNET'

auto '$VLAN_IF_TENANT'.'$VLAN_TAG_TENANT'
iface '$VLAN_IF_TENANT'.'$VLAN_TAG_TENANT' inet static
    vlan-raw-device '$VLAN_IF_TENANT'
    address '$IP_TENANT_SW_TENANT'
    netmask '$MASK_TENANT > /etc/network/interfaces

    echo $'8021q' > /etc/modules

}

configure_dpdk() {
    echo $'NR_2M_PAGES=2048' > /etc/dpdk/dpdk.conf

    sed -i -- 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="isolcpus=2-7 hugepages=2048"/g' /etc/default/grub

    echo $'devices/virtual/workqueue/cpumask = 3
devices/virtual/workqueue/writeback/cpumask = 3' >  /etc/sysfs.conf

    echo $'IRQBALANCE_BANNED_CPUS="FC"' > /etc/default/irqbalance

    echo $'<bus>      <id>           <driver> (uio_pci_generic ou vfio_pci)
pci     0000:00:14.0      uio_pci_generic
pci     0000:00:14.1      uio_pci_generic
pci     0000:00:14.2      uio_pci_generic
pci     0000:00:14.3      uio_pci_generic
pci     0000:05:00.0      uio_pci_generic
pci     0000:05:00.1      uio_pci_generic' > /etc/dpdk/interfaces

    systemctl enable dpdk

    grub-mkconfig -o /boot/grub/grub.cfg
}

configure_ovs() {
    update-alternatives --set ovs-vswitchd /usr/lib/openvswitch-switch-dpdk/ovs-vswitchd-dpdk
    systemctl restart openvswitch-switch.service

    ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
    ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="4096,0"
    ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=FC
    systemctl restart openvswitch-switch

    ovs-vsctl del-br "$OVS_BRIDGE_TENANT" 2> /dev/null
    ovs-vsctl add-br "$OVS_BRIDGE_TENANT" -- set bridge "$OVS_BRIDGE_TENANT" datapath_type=netdev protocols=OpenFlow13 fail-mode=secure

    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" dpdk-p0 tag="$VLAN_TAG_TENANT" -- set Interface dpdk-p0 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.0 ofport=1
    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" dpdk-p1 tag="$VLAN_TAG_TENANT" -- set Interface dpdk-p1 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.1 ofport=2
    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" dpdk-p2 tag="$VLAN_TAG_TENANT" -- set Interface dpdk-p2 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.2 ofport=3
    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" dpdk-p3 tag="$VLAN_TAG_TENANT" -- set Interface dpdk-p3 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.3 ofport=4
    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" dpdk-p4 tag="$VLAN_TAG_TENANT" -- set Interface dpdk-p4 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:05:00.0 ofport=5
    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" dpdk-p5 tag="$VLAN_TAG_TENANT" -- set Interface dpdk-p5 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:05:00.1 ofport=6
    ovs-vsctl add-port "$OVS_BRIDGE_TENANT" "$VLAN_IF_TENANT" tag="$VLAN_TAG_TENANT" -- set interface "$VLAN_IF_TENANT" type=internal -- set interface "$VLAN_IF_TENANT" mtu_request=9600

    ovs-vsctl set-controller "$OVS_BRIDGE_TENANT" tcp:127.0.0.1:6633
}

configure_ryu() {
    echo $'#!/bin/bash
    
ryu-manager /usr/local/lib/python2.7/dist-packages/ryu/app/simple_switch_13.py' > $(eval echo ~$USER)/ryu_controller.sh

    chmod +x $(eval echo ~$USER)/ryu_controller.sh

    echo $'[Unit]
Description=RYU Controller

[Service]
User='$(whoami)$'
TimeoutStartSec=0
WorkingDirectory='$(eval echo ~$USER)$'
ExecStart='$(eval echo ~$USER)$'/ryu_controller.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/ryu.service

    systemctl enable /etc/systemd/system/ryu.service
    systemctl start ryu.service
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

source parameters.conf

HOSTNAME=$(hostname)

configure_dns;
update_SO;
configure_network;
configure_dpdk;
configure_ovs;
configure_ryu;

