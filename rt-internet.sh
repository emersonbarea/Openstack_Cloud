#!/bin/bash


# Rwin 38:d5:47:0f:c8:14; fixed-address 192.168.200.228


update_SO() {
    sed -i -- 's/'$HOSTNAME'/'$HOSTNAME_RT_INTERNET'/g' /etc/hosts
    echo "$HOSTNAME_RT_INTERNET" > /etc/hostname
    hostname "$HOSTNAME_RT_INTERNET"
    apt update
    apt upgrade -y
    apt -f install -y
    apt autoremove -y
    apt install vim htop ethtool dpdk sysfsutils openvswitch-switch-dpdk python-pip ifupdown whois isc-dhcp-server bind9 host openvpn -y
    timedatectl set-timezone America/Sao_Paulo
}

configure_network() {
    apt autoremove netplan netplan.io nplan -y
    sed -i -- 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub

    echo $'auto lo
iface lo inet loopback

allow-hotplug eth4
iface eth4 inet static
    address '$OUTSIDE_IP'
    netmask '$OUTSIDE_MASK'
    dns-nameservers '$OUTSIDE_DNS'
    gateway '$OUTSIDE_GW'

allow-hotplug '$OVS_BRIDGE_INTERNET'
iface '$OVS_BRIDGE_INTERNET' inet static
    address '$IP_INTERNET_RT_INTERNET'
    netmask '$MASK_INTERNET'

allow-hotplug '$OVS_BRIDGE_INTERNET_VM_ADMIN'
iface '$OVS_BRIDGE_INTERNET_VM_ADMIN' inet static
    address '$IP_INTERNET_RT_INTERNET_VM_ADMIN'
    netmask '$MASK_INTERNET_ADMIN'
    
allow-hotplug '$OVS_BRIDGE_INTERNET_VM'
iface '$OVS_BRIDGE_INTERNET_VM' inet static
    address '$IP_INTERNET_RT_INTERNET_VM'
    netmask '$MASK_INTERNET_VM > /etc/network/interfaces
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

    ovs-vsctl del-br "$OVS_BRIDGE_INTERNET" 2> /dev/null
    ovs-vsctl add-br "$OVS_BRIDGE_INTERNET" -- set bridge "$OVS_BRIDGE_INTERNET" datapath_type=netdev
    ovs-vsctl add-port "$OVS_BRIDGE_INTERNET" dpdk-p0 -- set Interface dpdk-p0 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.0 ofport=1
   
    ovs-vsctl del-br "$OVS_BRIDGE_INTERNET_VM_ADMIN" 2> /dev/null
    ovs-vsctl add-br "$OVS_BRIDGE_INTERNET_VM_ADMIN" -- set bridge "$OVS_BRIDGE_INTERNET_VM_ADMIN" datapath_type=netdev
    ovs-vsctl add-port "$OVS_BRIDGE_INTERNET_VM_ADMIN" dpdk-p1 -- set Interface dpdk-p1 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.1 ofport=2

    ovs-vsctl del-br "$OVS_BRIDGE_INTERNET_VM" 2> /dev/null
    ovs-vsctl add-br "$OVS_BRIDGE_INTERNET_VM" -- set bridge "$OVS_BRIDGE_INTERNET_VM" datapath_type=netdev
    ovs-vsctl add-port "$OVS_BRIDGE_INTERNET_VM" dpdk-p2 -- set Interface dpdk-p2 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.2 ofport=3

    #ovs-vsctl add-port "$OVS_BRIDGE_INTERNET_VM" dpdk-p3 -- set Interface dpdk-p3 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:00:14.3 ofport=4
    #ovs-vsctl add-port "$OVS_BRIDGE_INTERNET_VM" dpdk-p4 -- set Interface dpdk-p4 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:05:00.0 ofport=5
    #ovs-vsctl add-port "$OVS_BRIDGE_INTERNET_VM" dpdk-p5 -- set Interface dpdk-p5 type=dpdk mtu_request=9600 options:dpdk-devargs=0000:05:00.1 ofport=6
}


configure_firewall() {
echo $'#!/bin/bash

# Definition of variables
ipt="/sbin/iptables"

INTERNET_IF="eth4"
INTERNAL_IF="'$OVS_BRIDGE_INTERNET'"
INTERNAL_IF_VM="'$OVS_BRIDGE_INTERNET_VM'"
INTERNAL_IF_VM_ADMIN="'$OVS_BRIDGE_INTERNET_VM_ADMIN'"

VPN_NET_ADMIN="'$NETWORK_VPN_NET_ADMIN'/'$PREFIX_LENGTH_VPN_NET_ADMIN'"
VPN_NET_VM="'$NETWORK_VPN_NET_VM'/'$PREFIX_LENGTH_VPN_NET_VM'"

VM_NET_ADMIN="'$NETWORK_INTERNET_ADMIN'/'$PREFIX_LENGTH_INTERNET_VM'"
VM_NET_VM="'$NETWORK_INTERNET_VM'/'$PREFIX_LENGTH_VPN_NET_VM'"

case $1 in
start)
echo "Initializing Firewall"
echo "Wait ..."
echo " "
# Sets default policy for defaults chains 
$ipt -P FORWARD DROP     # Forward policy
$ipt -P INPUT DROP      # Input policy 
$ipt -P OUTPUT ACCEPT   # Output policy
$ipt -F -t filter       # Filter rules flush
$ipt -F -t nat          # Nat rules flush
$ipt -F -t mangle       # Mangle rules flush
$ipt -X -t filter       # delete filter chains
$ipt -X -t nat          # delete nat chains
$ipt -X -t mangle       # delete mangle chains
$ipt -Z -t filter       # reset filter counters
$ipt -Z -t nat          # reset nat counters
$ipt -Z -t mangle       # reset mangle counters

#************************ INPUT **********************************#
# LoopBack
$ipt -A INPUT -i lo -j ACCEPT

# Handling established connections
$ipt -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# OpenVPN rules
$ipt -A INPUT -i $INTERNET_IF -p udp --dport 1194 -j ACCEPT

# DNS requests
$ipt -A INPUT -i $INTERNAL_IF -p udp --dport 53 -j ACCEPT
$ipt -A INPUT -i $INTERNAL_IF_VM -p udp --dport 53 -j ACCEPT
$ipt -A INPUT -i $INTERNAL_IF_VM_ADMIN -p udp --dport 53 -j ACCEPT

# Ping rule
$ipt -A INPUT -p icmp --icmp-type echo-request -i $INTERNET_IF -m limit --limit 1/s -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# SSH rule
$ipt -A INPUT -p tcp --dport 22 -j ACCEPT


#************************ FORWARD ******************************#
# LoopBack
$ipt -A FORWARD -i lo -j ACCEPT

# Handling established connections
$ipt -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Internet access
$ipt -A FORWARD -i $INTERNAL_IF -o $INTERNET_IF -j ACCEPT
$ipt -A FORWARD -i $INTERNAL_IF_VM -o $INTERNET_IF -j ACCEPT
$ipt -A FORWARD -i $INTERNAL_IF_VM_ADMIN -o $INTERNET_IF -j ACCEPT

# VPN nets rules
$ipt -A FORWARD -s $VPN_NET_ADMIN -j ACCEPT
$ipt -A FORWARD -s $VPN_NET_VM -d $VM_NET_VM -j ACCEPT

# Ping rule 
$ipt -A FORWARD -p icmp --icmp-type echo-request -i $INTERNAL_IF -o $INTERNET_IF -j ACCEPT
$ipt -A FORWARD -p icmp --icmp-type echo-request -i $INTERNAL_IF_VM -o $INTERNET_IF -j ACCEPT
$ipt -A FORWARD -p icmp --icmp-type echo-request -i $INTERNAL_IF_VM_ADMIN -o $INTERNET_IF -j ACCEPT
$ipt -A FORWARD -p icmp --icmp-type echo-request -s $VPN_NET_ADMIN -j ACCEPT


#*********************** ROUTING ********************************#

# Enabling routing
echo 1 > /proc/sys/net/ipv4/ip_forward

#********************* POSTROUTING ******************************#

# Masquerading Internet access
$ipt -t nat -A POSTROUTING -o $INTERNET_IF -j MASQUERADE


#********************* END CONFIGURATION ************************#

echo "Firewall is running ..."   > /var/tmp/firstatus
echo Date begin: $(date +%d/%m/%Y) >> /var/tmp/firstatus
echo Time begin: $(date +%X)       >> /var/tmp/firstatus
echo "Firewall started successfully.";;

status)
cat /var/tmp/firstatus;;

stop)

# Clear everything 
$ipt -P FORWARD ACCEPT   # Forward policy
$ipt -P INPUT ACCEPT    # Input policy 
$ipt -P OUTPUT ACCEPT   # Output policy
$ipt -F -t filter       # Filter rules flush
$ipt -F -t nat          # Nat rules flush
$ipt -F -t mangle       # Mangle rules flush
$ipt -X -t filter       # delete filter chains
$ipt -X -t nat          # delete nat chains
$ipt -X -t mangle       # delete mangle chains
$ipt -Z -t filter       # reset filter counters
$ipt -Z -t nat          # reset nat counters
$ipt -Z -t mangle       # reset mangle counters

# Disabling routing
echo 0 > /proc/sys/net/ipv4/ip_forward

echo "Firewall stopped"        > /var/tmp/firstatus
echo Date stop: $(date +%d/%m/%Y) >> /var/tmp/firstatus
echo Time stop: $(date +%X)       >> /var/tmp/firstatus
echo "ATTENTION:"
echo "  Firewall is stopped !!!";;

*)
echo "Use firewall with parameters: <start|status|stop>";;
esac' > /usr/bin/firewall

    chmod +x /usr/bin/firewall

    echo $'[Unit]
Description=Firewall
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/firewall start

[Install]
WantedBy=default.target' > /etc/systemd/system/firewall.service

    systemctl enable /etc/systemd/system/firewall.service
    systemctl start firewall.service
}

configure_dhcp() {
    echo $'default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;

authoritative;

subnet '$NETWORK_INTERNET' netmask '$MASK_INTERNET' {
  range '$DHCP_INTERNET_RANGE_BEGIN' '$DHCP_INTERNET_RANGE_END';
  option domain-name-servers '$DNS_INTERNET';
  option domain-name "'$DOMAIN_NAME'";
  option subnet-mask '$MASK_INTERNET';
  option routers '$GW_INTERNET';
  option broadcast-address '$BROADCAST_INTERNET';
  default-lease-time 600;
  max-lease-time 7200;
}

host '$HOSTNAME_SW_HP'    {hardware ethernet '$MAC_SW_HP'; fixed-address '$IP_INTERNET_SW_HP';}

host '$HOSTNAME_INFRA0'     {hardware ethernet '$MAC_INFRA0'; fixed-address '$IP_INTERNET_INFRA0';}
host '$HOSTNAME_COMPUTE00'  {hardware ethernet '$MAC_COMPUTE00'; fixed-address '$IP_INTERNET_COMPUTE00';}
host '$HOSTNAME_COMPUTE01'  {hardware ethernet '$MAC_COMPUTE01'; fixed-address '$IP_INTERNET_COMPUTE01';}
host '$HOSTNAME_COMPUTE02'  {hardware ethernet '$MAC_COMPUTE02'; fixed-address '$IP_INTERNET_COMPUTE02';}

host '$HOSTNAME_RARITAN'    {hardware ethernet '$MAC_RARITAN'; fixed-address '$IP_INTERNET_RARITAN';}
host '$HOSTNAME_DESKTOP00'    {hardware ethernet '$MAC_DESKTOP00'; fixed-address '$IP_INTERNET_DESKTOP00';}' > /etc/dhcp/dhcpd.conf

    systemctl enable isc-dhcp-server    
    systemctl restart isc-dhcp-server

}

configure_dns() {
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
    mkdir -p /etc/bind/domains/"$DOMAIN_NAME"/
    chown root.bind /etc/bind/domains/"$DOMAIN_NAME"

    echo $'zone "'$DOMAIN_NAME'" IN {
        type master;
        file "/etc/bind/domains/'$DOMAIN_NAME'/db.'$DOMAIN_NAME'";
};

zone "'$REVERSE_NETWORK'.in-addr.arpa" IN {
        type master;
        file "/etc/bind/domains/'$DOMAIN_NAME'/db.'$REVERSE_NETWORK'";
};' > /etc/bind/named.conf.local 

    echo $'@    IN SOA ns1.'$DOMAIN_NAME'. hostmaster.'$DOMAIN_NAME'. (
        2009032002 3H 15M 2W 1D )
        NS ns1.'$DOMAIN_NAME'.
        NS ns2.'$DOMAIN_NAME'.
        IN MX 10 smtp.'$DOMAIN_NAME'.
        IN MX 20 smtp2.'$DOMAIN_NAME'.
        IN MX 10 pop3.'$DOMAIN_NAME'.
'$DOMAIN_NAME'. A '$DNS_INTERNET'

ns1             A       '$DNS_INTERNET'
ns2             A       '$DNS_INTERNET'

'$HOSTNAME_RT_INTERNET'     A       '$IP_INTERNET_RT_INTERNET'
'$HOSTNAME_SW_HP'	    A       '$IP_INTERNET_SW_HP'

'$HOSTNAME_INFRA0'          A       '$IP_INTERNET_INFRA0'
'$HOSTNAME_COMPUTE00'       A       '$IP_INTERNET_COMPUTE00'
'$HOSTNAME_COMPUTE01'       A       '$IP_INTERNET_COMPUTE01'
'$HOSTNAME_COMPUTE02'       A       '$IP_INTERNET_COMPUTE02'

'$HOSTNAME_CASERVER'        A       '$IP_INTERNET_CASERVER'
'$HOSTNAME_RARITAN'         A       '$IP_INTERNET_RARITAN'
'$HOSTNAME_DESKTOP00'       A       '$IP_INTERNET_DESKTOP00 > /etc/bind/domains/"$DOMAIN_NAME"/db."$DOMAIN_NAME"

    REVERSE_DNS=$(echo "$DNS_INTERNET" | cut -d"." -f4)
    REVERSE_RT_INTERNET=$(echo "$IP_INTERNET_RT_INTERNET" | cut -d"." -f4)
    REVERSE_SW_HP=$(echo "$IP_INTERNET_SW_HP" | cut -d"." -f4)
    REVERSE_INFRA0=$(echo "$IP_INTERNET_INFRA0" | cut -d"." -f4)
    REVERSE_COMPUTE00=$(echo "$IP_INTERNET_COMPUTE00" | cut -d"." -f4)
    REVERSE_COMPUTE01=$(echo "$IP_INTERNET_COMPUTE01" | cut -d"." -f4)
    REVERSE_COMPUTE02=$(echo "$IP_INTERNET_COMPUTE02" | cut -d"." -f4)
    REVERSE_RARITAN=$(echo "$IP_INTERNET_RARITAN" | cut -d"." -f4)
    REVERSE_DESKTOP00=$(echo "$IP_INTERNET_DESKTOP00" | cut -d"." -f4)

    echo $'@    IN SOA ns1.'$DOMAIN_NAME'. hostmaster.'$DOMAIN_NAME'. (
        2009032001 3H 15M 2W 1D )
        NS ns1.'$DOMAIN_NAME'.
        NS ns2.'$DOMAIN_NAME'.

'$REVERSE_DNS'     PTR     ns1.'$DOMAIN_NAME'.
'$REVERSE_DNS'     PTR     ns2.'$DOMAIN_NAME'.

'$REVERSE_DNS'     PTR     smtp.'$DOMAIN_NAME'.
'$REVERSE_DNS'     PTR     smtp2.'$DOMAIN_NAME'.
'$REVERSE_DNS'     PTR     pop3.'$DOMAIN_NAME'.

'$REVERSE_RT_INTERNET'	PTR     '$HOSTNAME_RT_INTERNET'.'$DOMAIN_NAME'.
'$REVERSE_SW_HP'     	PTR     '$HOSTNAME_SW_HP'.'$DOMAIN_NAME'.

'$REVERSE_INFRA0'     	PTR     '$HOSTNAME_INFRA0'.'$DOMAIN_NAME'.
'$REVERSE_COMPUTE00'    PTR     '$HOSTNAME_COMPUTE00'.'$DOMAIN_NAME'.
'$REVERSE_COMPUTE01'    PTR     '$HOSTNAME_COMPUTE01'.'$DOMAIN_NAME'.
'$REVERSE_COMPUTE02'    PTR     '$HOSTNAME_COMPUTE02'.'$DOMAIN_NAME'.

'$REVERSE_RARITAN'     	PTR     '$HOSTNAME_RARITAN'.'$DOMAIN_NAME'. 
'$REVERSE_DESKTOP00'    PTR     '$HOSTNAME_DESKTOP00'.'$DOMAIN_NAME'.' > /etc/bind/domains/"$DOMAIN_NAME"/db."$REVERSE_NETWORK"

    rm -rf /etc/bind/named.conf.options
    echo $'options {
    directory "/var/cache/bind";

    forwarders { '$OUTSIDE_DNS'; };

    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;

    auth-nxdomain no;
    listen-on-v6 { any; };
};' > /etc/bind/named.conf.options

    rm -rf /etc/resolv.conf
    echo $'search '$DOMAIN_NAME'
nameserver 127.0.0.1' > /etc/resolv.conf
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

source parameters.conf

HOSTNAME=$(hostname)
HOME_DIR=$(eval echo "~$different_user")

update_SO;
configure_network;
configure_dpdk;
configure_ovs;
configure_firewall;
configure_dhcp;
configure_dns;