# Openstack-Cloud

What do you want to do?

[Install Openstack](#install-openstack)

[Configure VPN Server](#configure-vpn-server)

[Manage VPN Users](#manage-vpn-users)

## Install Openstack

First of all, install Ubuntu Server LTS 18.04 on all servers and WhiteBox switch.

Connect all machines like [Openstack_Cloud.pdf](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf) topology.

**Attention:** before next steps, make sure you have access to ```rt-internet``` (console or ssh). ```rt-internet``` must also be able to access internet using ```wget``` and ```apt```.

Go to ```rt-internet``` and run [git clone https://github.com/emersonbarea/Openstack_Cloud.git](https://github.com/emersonbarea/Openstack_Cloud).

Check ```parameters.conf``` file to verify if the parameters values represents your environment.

Now, execute the procedures below:

1. Access the HP 2910 switch (```sw-hp```) by console, and ```Ctrl + c``` and ```Ctrl + v``` the configuration existent in [sw-hp.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp.md) file.

2. On ```rt-internet``` machine, execute ```cd ~/Openstack_Cloud``` and ```sudo rt-internet.sh```
	- this procedure configures ```rt-internet``` to be a DHCP server, DNS server and Firewall server to other machines
	
3. On ```sw-hp``` console, ```Ctrl + c``` and ```Ctrl + v``` the configuration existent in [sw-hp-shutdown_all_servers_interfaces.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-shutdown_all_servers_interfaces.md) file.

4. On ```sw-hp``` console, ```Ctrl + c``` and ```Ctrl + v``` the configuration existent in [sw-hp-up_only_first_network_interface_on_each_server.md](https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp-up_only_first_network_interface_on_each_server.md) file.

5. Go to ```infra0```, ```compute00```, ```compute01``` and ```compute02``` servers, and find for the network interface with the mac address correponding to the ```eth0``` interface presented in the [topology file](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf). After that, execute the commands below:
	- ```ifconfig <interface> up```
	- ```dhclient <interface>```
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
	- open your internet browser and go to ```http://<infra_node_IP>```

     	- username: ```admin```
    	- password: ```<output of cat command above>```

13. 

## Configure VPN Server

The VPN server should to be configured only one time. If you want create users, go to [Manage VPN Users](#manage-vpn-users).


```rt-internet``` is 



## Manage VPN Users