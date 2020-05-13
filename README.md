# Openstack-Cloud

First of all, install Ubuntu Server LTS 18.04 on all servers and WhiteBox switches.

Connect all machines like ```Openstack_Cloud.pdf``` topology.

Attention: before any step, make sure you have ssh access to ```sw-internet```. The ```sw-internet``` must also be able to access the internet.

run ```git clone https://github.com/emersonbarea/Openstack-Cloud.git``` in ```sw-internet```.

Check the ```parameters.conf``` file to verify the parameters that will be used to configure automatically the servers and switches.

Attention: all steps below must be performed from ```sw-internet```.

1.) execute ```sudo sw-internet_first_of_all.sh```
- this procedure configures ```sw-internet``` to be a dhcp server, dns server and firewall server to other machines
- now, you should be able to ```ping``` all servers and switches (by DNS name and IP)

2) execute ```./scp.sh``` to copy the all corresponding files to each server and switch.

3) ssh into ```infra0``` server and configure it:
3.1) ```ssh infra0```
3.2) ```sudo ./all_openstack_servers.sh```
3.3) ```sudo reboot```

4) ssh into ```compute00``` server and configure it:
4.1) ```ssh compute00```
4.2) ```sudo ./all_openstack_servers.sh```
4.3) ```sudo reboot```

5) ssh into ```compute01``` server and configure it:
5.1) ```ssh compute01```
5.2) ```sudo ./all_openstack_servers.sh```
5.3) ```sudo reboot```

6) ssh into ```compute02``` server and configure it:
6.1) ```ssh compute02```
6.2) ```sudo ./all_openstack_servers.sh```
6.3) ```sudo reboot```

7) ssh into ```sw-mgmt``` switch and configure it:
7.1) ```ssh sw-mgmt```
7.2) ```sudo ./sw-mgmt.sh```
7.3) ```sudo reboot```

8) ssh into ```sw-tenant``` switch and configure it:
8.1) ```ssh sw-tenant```
8.2) ```sudo ./sw-tenant.sh```
8.3) ```sudo reboot```

9) complete the ```sw-internet``` configuration:
9.1) ```sudo ./sw-internet.sh```
9.3) ```sudo reboot```

Now, all network parameters should be read to install Openstack. Continue following the steps bellow:

10) ssh into ```infra0``` server and configure it:
10.1) ```ssh infra0```
10.2) ```sudo ./only_infra_server.sh```
      
      take 5 coffees and two cup of water.

10.3) execute ```cat /etc/openstack_deploy/user_secrets.yml | grep keystone_auth_admin_password``` to know dashboard ```admin``` password
10.4) open your internet browser and go to ```http://<infra_node_IP>```

      username: ```admin```
      password: ```<output of cat command above>```