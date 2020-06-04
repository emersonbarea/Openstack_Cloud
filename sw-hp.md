To configure the HP switch, Ctrl+c and Ctrl+v the configuration bellow:

```configure terminal
hostname "sw-hp"
trunk 1-4 trk1 lacp
trunk 5-8 trk2 lacp
trunk 9-12 trk3 lacp
trunk 15-18 trk4 lacp
no telnet-server
interface 14
   disable
   name "PORTA COM DEFEITO"
   exit
no snmp-server enable
no snmp-server community "public" unrestricted
vlan 1
   name "vlan-internet"
   no untagged 46-47
   untagged 13-14,19-45,48,Trk1-Trk4
   ip address 192.168.200.253 255.255.255.0
   exit
vlan 16
   name "vlan-mgmt"
   tagged Trk1-Trk4
   ip address 172.16.0.254 255.255.255.0
   exit
vlan 17
   name "vlan-tenant"
   tagged Trk1-Trk4
   ip address 172.16.1.254 255.255.255.0
   exit
vlan 18
   name "vlan-storage"
   tagged Trk1-Trk4
   ip address 172.16.2.254 255.255.255.0
   exit
vlan 201
   name "vlan-internet-admin"
   untagged 47
   tagged Trk1-Trk4
   ip address 192.168.201.253 255.255.255.0
   exit
vlan 202
   name "vlan-internet-vm"
   untagged 46
   tagged Trk1-Trk4
   ip address 192.168.202.253 255.255.255.0
   exit
no autorun```

and create all users password (manager and operator) with the command bellow:

```
configure terminal
password all
```
Obs.: you will be asked for users password

To enable SSH access, Ctrl+c and Ctrl+v the commands bellow:

```
configure terminal
crypto key generate ssh rsa bits 1024
ip ssh
```
