# Openstack-Cloud

What do you want to do?

[Install Openstack](#install-openstack)

[Initiate Openstack configuration](#initiate-openstack-configuration)

[Configure VPN Server](#configure-vpn-server)

[Manage VPN Users](#manage-vpn-users)

## Install Openstack

First of all, install Ubuntu Server LTS 18.04 on all servers and WhiteBox switch.

Connect all machines following [Openstack_Cloud.pdf](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf) topology.

**Obs.:** before next steps, make sure you have access to ```rt-internet``` (console or ssh). ```rt-internet``` must also be able to access Internet using ```wget``` and ```apt```.

Go to ```rt-internet``` and run [git clone https://github.com/emersonbarea/Openstack_Cloud.git](https://github.com/emersonbarea/Openstack_Cloud).

Check ```parameters.conf``` file and ensure the values represents your environment.

Now, execute the procedures below:

1. Access the HP 2910 switch (```sw-hp```) console, and ```Ctrl + c``` and ```Ctrl + v``` the configuration from the [sw-hp.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp.md) file.

2. At ```rt-internet```, execute ```cd ~/Openstack_Cloud``` and ```sudo rt-internet.sh```
	- this procedure configures ```rt-internet``` to be a DHCP server, DNS server and Firewall
	
3. At ```sw-hp``` console, ```Ctrl + c``` and ```Ctrl + v``` the configuration from the [sw-hp-shutdown_all_servers_interfaces.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-shutdown_all_servers_interfaces.md) file.

4. At ```sw-hp``` console, ```Ctrl + c``` and ```Ctrl + v``` the configuration from the [sw-hp-up_only_first_network_interface_on_each_server.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-up_only_first_network_interface_on_each_server.md) file.

5. Go to ```infra0```, ```compute00```, ```compute01```, ```compute02```, ```compute03```, ```compute04``` servers, and find for the network interface with the mac address correponding to the ```eth0``` interface configured in the [topology file](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf). After that, execute the commands below:
	- ```ifconfig <interface> up```
	- ```dhclient <interface>```
	- ```ifconfig```
		- verify if the IP address assigned by DHCP server corresponds to the [topology](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf)

6. execute the command ```fping -f fping.txt```, and look if all servers ```is alive```.
	- if any server is ```Unreachable```, reconfigure its network interface following the steps above.

7. At ```rt-internet```, execute ```./scp.sh``` to copy the all corresponding files to each server.

8. ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

9. ssh into ```compute00``` server and configure it:
	- ```ssh compute00```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

10. ssh into ```compute01``` server and configure it:
	- ```ssh compute01```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

11. ssh into ```compute02``` server and configure it:
	- ```ssh compute02```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

12. ssh into ```compute03``` server and configure it:
	- ```ssh compute03```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

13. ssh into ```compute04``` server and configure it:
	- ```ssh compute04```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

Now, all network parameters should be read to install Openstack. Follow the steps bellow:

14. turn up all ```sw-hp``` interfaces executing the commands from the [sw-hp-up_all_servers_interface.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-up_all_servers_interface.md) file.

15. ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./only_infra_server.sh```
      
    	- take 5 coffees and a cup of water.

	- execute ```cat /etc/openstack_deploy/user_secrets.yml | grep keystone_auth_admin_password``` to know dashboard ```admin``` password
	- open your internet browser and go to ```http://<*infra_node_IP*>```

     	- username: ```admin```
    	- password: ```<*output of cat command above*>```

## Initiate Openstack configuration

This procedures makes the initial Openstack configuration. To do it, follow the procedure below using ```root``` user in ```infra0``` server:

```
lxc-ls | grep infra_utility_container
lxc-attach infra_utility_container-<container identifier>
cd /root
source openrc
```

#### Generating ssh Key to be used in VMs

```openstack keypair create default > default.pem```


#### Downloading ISO image files and creating Openstack images

```
wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

openstack image create --file cirros-0.5.1-x86_64-disk.img --disk-format qcow2 --container-format bare --public cirros
openstack image create --file bionic-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public bionic-server
```

#### Creating Flavors

```
openstack flavor create --ram 512 --disk 1 --vcpus 1 m1.tiny
openstack flavor create --ram 2048 --disk 20 --vcpus 1 m1.small
openstack flavor create --ram 4096 --disk 40 --vcpus 1 m1.medium
openstack flavor create --ram 8192 --disk 80 --vcpus 1 m1.large
openstack flavor create --ram 16384 --disk 160 --vcpus 1 m1.xlarge
```

#### Creating Admin External Network

```
openstack network create --external external-admin-net --availability-zone-hint nova --provider-network-type flat --provider-physical-network padmin --share

openstack subnet create --network external-admin-net --subnet-range 192.168.201.0/24 --allocation-pool start=192.168.201.1,end=192.168.201.200 --dhcp --gateway 192.168.201.254 --ip-version 4 --dns-nameserver 192.168.200.254 external-admin-subnet
```

#### Importing CA-Server image from snapshot

```
openstack security group create --description "Security Group to CA-Server virtual host" CA-Server-Security-Group
openstack security group rule create --ingress --protocol icmp --remote-ip 0.0.0.0/0 CA-Server-Security-Group
openstack security group rule create --ingress --protocol tcp --remote-ip 0.0.0.0/0 CA-Server-Security-Group
openstack security group rule create --ingress --protocol udp --remote-ip 0.0.0.0/0 CA-Server-Security-Group
```

```openstack image create CA-Server --container-format bare --disk-format qcow2 --file CA-Server.raw```

```openstack server create --flavor m1.small --image CA-Server --key-name default --nic net-id=$(openstack network show external-admin-net | grep " id" | awk '{print $4}'),v4-fixed-ip=192.168.201.252 --security-group CA-Server-Security-Group CA-Server```


#### Creating VM's External Network

```
openstack network create --external external-vm-net --availability-zone-hint nova --provider-network-type flat --provider-physical-network pvm --share

openstack subnet create --network external-vm-net --subnet-range 192.168.202.0/24 --allocation-pool start=192.168.202.1,end=192.168.202.200 --dhcp --gateway 192.168.202.254 --ip-version 4 --dns-nameserver 192.168.200.254 external-vm-subnet
```

#### Creating VM's Internal Network

```
openstack network create --internal --availability-zone-hint nova internal-net
openstack subnet create --network internal-net --subnet-range 192.168.0.0/24 --dhcp --gateway 192.168.0.1 --ip-version 4 --dns-nameserver 192.168.200.254 internal-subnet
```

#### Creating VM's Internet Router

```
openstack router create --availability-zone-hint nova internet-router-vm
openstack router add subnet internet-router-vm internal-subnet
openstack router set --external-gateway external-vm-net --enable-snat internet-router-vm
```

#### Creating test VMs

```
openstack server create --flavor m1.tiny --image cirros --key-name default --network internal-net cirros_1
openstack server show cirros_1
openstack server create --flavor m1.tiny --image cirros --key-name default --network internal-net cirros_2
openstack server show cirros_2
```

Obs.: if you want to pin a VM to a especific compute node, make:

```
openstack server create --flavor m1.tiny --image cirros --key-name default cirros_1 --availability-zone nova:compute00
```

## Configure VPN Server

The VPN server should be configured only one time. If you want to create users, go to [Manage VPN Users](#manage-vpn-users) section.

***Attention***: this procedure should be performed only after [Initial Openstack configuration](#initiate-openstack-configuration) procedure.

1. At ```rt-internet```, execute the command below:
	- ```sudo ./rt-internet_configure_vpn.sh```


## Manage VPN Users

1. Make sure ```CA-Server``` VM is up and running in Openstack infrastructure

2. Make sure ```rt-internet``` can ping and access ```CA-Server``` using ssh with ```root``` user (```ssh root@ca-server```)

3. Put the usernames or identifiers into ```~/Openstack_Cloud/OpenVPN/users.conf``` file.
	- Ex.:
	```
	Juclealdo Silva
	Astrogenio Bordegas
	Juju Neves
	```

2. execute the command below:
	- ```sudo ./manage_vpn.sh```

3. now, send the certificates to each user using secure channel, like scp:
	- Obs.: the certificates are stored in ```~/client-configs/files/```
