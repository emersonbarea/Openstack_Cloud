# Openstack-Ansible

First of all, install Ubuntu Server LTS 18.04. 

run ```git clone https://github.com/emersonbarea/Openstack-Ansible.git``` in your personal computer

edit ```vi IPs.conf```

run ```./scp.sh```

go to (ssh) infra and all computes nodes

run ```./run_on_all_nodes.sh``` on all nodes

```reboot``` all nodes

run ```./run_only_on_infra.sh``` only on infra node

take 5 coffees and two cup of water...

go to (ssh) infra

run ```cat /etc/openstack_deploy/user_secrets.yml | grep keystone_auth_admin_password``` to know dashboard ```admin``` password

open your personal computer browser and go to ```http://<infra_node_IP>```

username: ```admin```
password: ```<output of cat command above>```
