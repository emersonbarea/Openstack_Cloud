# Openstack-Cloud

First of all, install Ubuntu Server LTS 18.04 on all servers and WhiteBox switches.

Connect all machines like [Openstack_Cloud.pdf](https://github.com/emersonbarea/Openstack_Cloud/blob/master/Openstack_Cloud.pdf) topology.

**Attention:** before any step, make sure you have ssh access to ```sw-internet```. The ```sw-internet``` must also be able to access the internet.

run [git clone https://github.com/emersonbarea/Openstack_Cloud.git](https://github.com/emersonbarea/Openstack_Cloud) in ```sw-internet```.

Check the ```parameters.conf``` file to verify the parameters that will be used to configure automatically the servers and switches.

**Attention:** all steps below must be performed from ```sw-internet```.

**1.** execute ```sudo sw-internet_first_of_all.sh```
	- this procedure configures ```sw-internet``` to be a dhcp server, dns server and firewall server to other machines
	- now, you should be able to ```ping``` all servers and switches (by DNS name and IP)

**2.** execute ```./scp.sh``` to copy the all corresponding files to each server and switch.

**3.** ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

**4.** ssh into ```compute00``` server and configure it:
	- ```ssh compute00```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

**5.** ssh into ```compute01``` server and configure it:
	- ```ssh compute01```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

**6.** ssh into ```compute02``` server and configure it:
	- ```ssh compute02```
	- ```sudo ./all_openstack_servers.sh```
	- ```sudo reboot```

**7.** ssh into ```sw-mgmt``` switch and configure it:
	- ```ssh sw-mgmt```
	- ```sudo ./sw-mgmt.sh```
	- ```sudo reboot```

**8.** ssh into ```sw-tenant``` switch and configure it:
	- ```ssh sw-tenant```
	- ```sudo ./sw-tenant.sh```
	- ```sudo reboot```

**9.** complete the ```sw-internet``` configuration:
	- ```sudo ./sw-internet.sh```
	- ```sudo reboot```

Now, all network parameters should be read to install Openstack. Continue following the steps bellow:

**10.** ssh into ```infra0``` server and configure it:
	- ```ssh infra0```
	- ```sudo ./only_infra_server.sh```
      
    	- take 5 coffees and two cup of water.

	- execute ```cat /etc/openstack_deploy/user_secrets.yml | grep keystone_auth_admin_password``` to know dashboard ```admin``` password
	- open your internet browser and go to ```http://<infra_node_IP>```

     	- username: ```admin```
    	- password: ```<output of cat command above>```