# Openstack-Cloud

What do you want to do?

[Install Openstack](#install-openstack)

[Configure VPN Server](#configure-vpn-server)

[Initial Openstack configuration](#initial-openstack-configuration)

[Manage VPN Users](#manage-vpn-users)

## Install Openstack

First of all, install Ubuntu Server LTS 18.04 on all servers and WhiteBox switch.

Connect all machines like [Openstack_Cloud.pdf](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf) topology.

**Attention:** before next steps, make sure you have access to ```rt-internet``` (console or ssh). ```rt-internet``` must also be able to access internet using ```wget``` and ```apt```.

Go to ```rt-internet``` and run [git clone https://github.com/emersonbarea/Openstack_Cloud.git](https://github.com/emersonbarea/Openstack_Cloud).

Check ```parameters.conf``` file to verify if the parameters values represents your environment.

Now, execute the procedures below:

1. Access the HP 2910 switch (```sw-hp```) by console, and ```Ctrl + c``` and ```Ctrl + v``` the configuration existent in [sw-hp.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp.md) file.

2. At ```rt-internet``` machine, execute ```cd ~/Openstack_Cloud``` and ```sudo rt-internet.sh```
	- this procedure configures ```rt-internet``` to be a DHCP server, DNS server and Firewall server to other machines
	
3. At ```sw-hp``` console, ```Ctrl + c``` and ```Ctrl + v``` the configuration existent in [sw-hp-shutdown_all_servers_interfaces.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-shutdown_all_servers_interfaces.md) file.

4. At ```sw-hp``` console, ```Ctrl + c``` and ```Ctrl + v``` the configuration existent in [sw-hp-up_only_first_network_interface_on_each_server.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-up_only_first_network_interface_on_each_server.md) file.

5. Go to ```infra0```, ```compute00```, ```compute01``` and ```compute02``` servers, and find for the network interface with the mac address correponding to the ```eth0``` interface presented in the [topology file](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf). After that, execute the commands below:
	- ```ifconfig <*interface*> up```
	- ```dhclient <*interface*>```
	- ```ifconfig```
		- validate if the IP address configured by DHCP server corresponds to the [topology](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf)

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

Now, all network parameters should be read to install Openstack. Continue following the steps bellow:

12. ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./only_infra_server.sh```
      
    	- take 5 coffees and a cup of water.

	- execute ```cat /etc/openstack_deploy/user_secrets.yml | grep keystone_auth_admin_password``` to know dashboard ```admin``` password
	- open your internet browser and go to ```http://<*infra_node_IP*>```

     	- username: ```admin```
    	- password: ```<*output of cat command above*>```

## Initial Openstack configuration

This procedures makes the initional Openstack configuration. To do it, follow the procedure below logged with ```root``` at ```infra0``` server:

```
lxc-ls | grep infra_utility_container
lxc-attach infra_utility_container-<*container identifier*>
cd /root
source openrc
```

#### ssh Key

openstack keypair create default > default.pem


# IMAGES

wget http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

openstack image create --file xenial-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public xenial-server
openstack image create --file cirros-0.5.1-x86_64-disk.img --disk-format qcow2 --container-format bare --public cirros
openstack image create --file bionic-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public bionic-server

# FLAVORS

openstack flavor create --ram 512 --disk 1 --vcpus 1 m1.tiny
openstack flavor create --ram 2048 --disk 20 --vcpus 1 m1.small
openstack flavor create --ram 4096 --disk 40 --vcpus 1 m1.medium
openstack flavor create --ram 8192 --disk 80 --vcpus 1 m1.large
openstack flavor create --ram 16384 --disk 160 --vcpus 1 m1.xlarge

# ADMINISTRATIVE EXTERNAL NETWORK

openstack network create --external external-admin-net --availability-zone-hint nova --provider-network-type flat --provider-physical-network padmin --share

openstack subnet create --network external-admin-net --subnet-range 192.168.201.0/24 --allocation-pool start=192.168.201.1,end=192.168.201.200 --dhcp --gateway 192.168.201.254 --ip-version 4 --dns-nameserver 192.168.200.254 external-admin-subnet

# CA-SERVER
openstack security group create --description "Security Group to CA-Server virtual host" CA-Server-Security-Group
openstack security group rule create --ingress --protocol icmp --remote-ip 0.0.0.0/0 CA-Server-Security-Group




#regra momentanea
openstack security group rule create --ingress --protocol tcp --remote-ip 0.0.0.0/0 CA-Server-Security-Group
openstack security group rule create --ingress --protocol udp --remote-ip 0.0.0.0/0 CA-Server-Security-Group




openstack server create --flavor m1.small --image bionic-server --key-name default --nic net-id=$(openstack network show external-admin-net | grep " id" | awk '{print $4}'),v4-fixed-ip=192.168.201.252 --security-group CA-Server-Security-Group CA-Server

# SECURITY GROUP PERMIT ALL
openstack security group create --description "Security Group Description" Security-Group-Name
openstack security group rule create --ingress --protocol icmp --remote-ip 0.0.0.0/0 Security-Group-Name
openstack security group rule create --ingress --protocol tcp --remote-ip 0.0.0.0/0 Security-Group-Name
openstack security group rule create --ingress --protocol udp --remote-ip 0.0.0.0/0 Security-Group-Name

# ANOTHER EXTERNAL HOST (EXAMPLE - dynamic IP attribution)
####openstack server create --flavor m1.small --image bionic-server --key-name default --network external-admin-net ServerName


# VM EXTERNAL NETWORK
openstack network create --external external-vm-net --availability-zone-hint nova --provider-network-type flat --provider-physical-network pvm --share
openstack subnet create --network external-vm-net --subnet-range 192.168.202.0/24 --allocation-pool start=192.168.202.1,end=192.168.202.200 --dhcp --gateway 192.168.202.254 --ip-version 4 --dns-nameserver 192.168.200.254 external-vm-subnet

openstack network create --internal --availability-zone-hint nova internal-net
openstack subnet create --network internal-net --subnet-range 192.168.0.0/24 --dhcp --gateway 192.168.0.1 --ip-version 4 --dns-nameserver 192.168.200.254 internal-subnet

openstack router create --availability-zone-hint nova internet-router-vm
openstack router add subnet internet-router-vm internal-subnet
openstack router set --external-gateway external-vm-net --enable-snat internet-router-vm

openstack server create --flavor m1.tiny --image cirros --key-name default --network internal-net cirros_1
openstack server show cirros_1
openstack server create --flavor m1.tiny --image cirros --key-name default --network internal-net cirros_2
openstack server show cirros_2

openstack server create --flavor m1.tiny --image cirros --key-name default cirros_1 --availability-zone nova:compute00

## VM BACKUP AND RESTORE (USING SNAPSHOT)

https://docs.openstack.org/ocata/user-guide/cli-use-snapshots-to-migrate-instances.html

openstack server create --flavor m1.small --image CA-Server --key-name default --nic net-id=$(openstack network show external-admin-net | grep " id" | awk '{print $4}'),v4-fixed-ip=192.168.201.252 --security-group CA-Server-Security-Group CA-Server




## Configure VPN Server

The VPN server should be configured only one time. If you want to create users, go to [Manage VPN Users](#manage-vpn-users) section.

1. Restore the ```CA-Server``` raw image to the ```infra0``` server
	- use ```scp``` or other transfer file program to do it.

2. At ```infra0``` server, execute the commands below:
	- 


1. At ```rt-internet```, execute the command below:
	- ```sudo ./rt-internet_configure_vpn.sh```



## Manage VPN Users