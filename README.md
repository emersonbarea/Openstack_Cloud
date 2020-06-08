# Openstack-Cloud

First of all, install Ubuntu Server LTS 18.04 on all servers and WhiteBox switch.

Connect all machines like [Openstack_Cloud.pdf](https://github.com/emersonbarea/Openstack_Cloud/blob/master/topology/Openstack_Cloud.pdf) topology.

**Attention:** before next steps, make sure you have access to ```rt-internet``` (console or ssh). ```rt-internet``` must also be able to access internet using ```wget``` and ```apt```.

Go to ```rt-internet``` and run [git clone https://github.com/emersonbarea/Openstack_Cloud.git](https://github.com/emersonbarea/Openstack_Cloud).

Check ```parameters.conf``` file to verify if the parameters values represents your environment.

Now, log to ```rt-internet``` and execute the commands below:

1. Access the HP switch 2910 by console, and ```Ctrl + c``` + ```Ctrl + v``` the configuration existent in [https://github.com/emersonbarea/Openstack_Cloud/blob/master/sw-hp.md] ```sw-hp.md``` file.

1. execute ```cd ~/Openstack_Cloud``` and ```sudo rt-internet.sh```
	- this procedure configures ```rw-internet``` to be a DHCP server, DNS server and Firewall server to other machines
	- now, you should be able to ```ping``` all servers and switches (by DNS name and IP)

2. execute ```./scp.sh``` to copy the all corresponding files to each server and switch.

3. ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

4. ssh into ```compute00``` server and configure it:
	- ```ssh compute00```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

5. ssh into ```compute01``` server and configure it:
	- ```ssh compute01```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

6. ssh into ```compute02``` server and configure it:
	- ```ssh compute02```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

7. ssh into ```sw-mgmt``` switch and configure it:
	- ```ssh sw-mgmt```
	- ```sudo ./sw-mgmt.sh```
	- ```sudo reboot```

8. ssh into ```sw-tenant``` switch and configure it:
	- ```ssh sw-tenant```
	- ```sudo ./sw-tenant.sh```
	- ```sudo reboot```

9. complete the ```sw-internet``` configuration:
	- ```sudo ./sw-internet.sh```
	- ```sudo reboot```

Now, all network parameters should be read to install Openstack. Continue following the steps bellow:

10. ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./only_infra_server.sh```
      
    	- take 5 coffees and two cup of water.

	- execute ```cat /etc/openstack_deploy/user_secrets.yml | grep keystone_auth_admin_password``` to know dashboard ```admin``` password
	- open your internet browser and go to ```http://<infra_node_IP>```

     	- username: ```admin```
    	- password: ```<output of cat command above>```