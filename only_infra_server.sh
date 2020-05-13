#!/bin/bash

configure_ssh() {
  scp -i /root/default.pem root@"$PUBLIC_IP_COMPUTE00":/root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub."$HOSTNAME_COMPUTE00"
  scp -i /root/default.pem root@"$PUBLIC_IP_COMPUTE01":/root/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub."$HOSTNAME_COMPUTE01"
  cat /root/.ssh/id_rsa.pub."$HOSTNAME_COMPUTE00" >> /root/.ssh/authorized_keys
  cat /root/.ssh/id_rsa.pub."$HOSTNAME_COMPUTE01" >> /root/.ssh/authorized_keys
  scp -i /root/default.pem /root/.ssh/authorized_keys root@"$PUBLIC_IP_COMPUTE00":/root/.ssh/authorized_keys
  scp -i /root/default.pem /root/.ssh/authorized_keys root@"$PUBLIC_IP_COMPUTE01":/root/.ssh/authorized_keys

  ssh "$BR_MGMT_IP_INFRA" 'exit'
  ssh "$BR_MGMT_IP_COMPUTE00" 'exit'
  ssh "$BR_MGMT_IP_COMPUTE01" 'exit'
  ssh "$BR_VXLAN_IP_INFRA" 'exit'
  ssh "$BR_VXLAN_IP_COMPUTE00" 'exit'
  ssh "$BR_VXLAN_IP_COMPUTE01" 'exit'
}

download_openstack() {
  git clone -b 18.1.1 https://git.openstack.org/openstack/openstack-ansible /opt/openstack-ansible
}

configure_openstack_user_confi_yml() {
  echo -e '# Host IPs:
# infra_public_addr      = '$PUBLIC_IP_INFRA'
# compute0_public_addr   = '$PUBLIC_IP_COMPUTE00'
# compute1_public_addr   = '$PUBLIC_IP_COMPUTE01'

cidr_networks:
  container: '$NETWORK_CONTAINER'
  tunnel: '$NETWORK_TUNNEL'

used_ips:
  - '$PUBLIC_IP_INFRA'
  - '$PUBLIC_IP_COMPUTE00'
  - '$PUBLIC_IP_COMPUTE01'
  - "'$BR_MGMT_IP_INFRA','$BR_MGMT_IP_COMPUTE01'"
  - "'$BR_VXLAN_IP_INFRA','$BR_VXLAN_IP_COMPUTE01'"

global_overrides:
  internal_lb_vip_address: '$BR_MGMT_IP_INFRA'
  external_lb_vip_address: '$PUBLIC_IP_INFRA'
  management_bridge: "br-mgmt"
  provider_networks:
    - network:
        container_bridge: "br-mgmt"
        container_type: "veth"
        container_interface: "eth1"
        ip_from_q: "container"
        type: "raw"
        group_binds:
          - all_containers
          - hosts
        is_container_address: true
    - network:
        container_bridge: "br-vxlan"
        container_type: "veth"
        container_interface: "eth10"
        ip_from_q: "tunnel"
        type: "vxlan"
        range: "1:1000"
        net_name: "vxlan"
        group_binds:
          - neutron_linuxbridge_agent

###
### Infrastructure
###

# galera, memcache, rabbitmq, utility
shared-infra_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# repository (apt cache, python packages, etc)
repo-infra_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# load balancer
haproxy_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

###
### OpenStack
###

# keystone
identity_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# cinder api services
storage-infra_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# glance
image_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# nova api, conductor, etc services
compute-infra_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# heat
orchestration_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# horizon
dashboard_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# neutron server, agents (L3, etc)
network_hosts:
  infra:
    ip: '$BR_MGMT_IP_INFRA'

# nova hypervisors
compute_hosts:
  compute00:
    ip: '$BR_MGMT_IP_COMPUTE00'
  compute01:
    ip: '$BR_MGMT_IP_COMPUTE01 > /root/openstack_user_config.yml

}

configure_openstack() {
  cd /opt/openstack-ansible
  git checkout -b 18.1.1 18.1.1
  ./scripts/bootstrap-ansible.sh
  cp -R etc/openstack_deploy/ /etc/openstack_deploy
  cp /root/openstack_user_config.yml /etc/openstack_deploy/openstack_user_config.yml
  echo -e 'install_method: "source"
galera_monitoring_allowed_source: "0.0.0.0/0"
neutron_l2_population: "true"' >  /etc/openstack_deploy/user_variables.yml
  ./scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml
}

install_openstack() {
  cd /opt/openstack-ansible/playbooks/
  openstack-ansible setup-infrastructure.yml --syntax-check
  openstack-ansible setup-hosts.yml
  openstack-ansible setup-infrastructure.yml
  openstack-ansible setup-openstack.yml
}


source IPs.conf

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

HOSTNAME=$(hostname)
HOSTNAME_INFRA='infra'
HOSTNAME_COMPUTE00='compute00'
HOSTNAME_COMPUTE01='compute01'
BR_MGMT_IP_INFRA='172.16.0.1'
BR_MGMT_IP_COMPUTE00='172.16.0.2'
BR_MGMT_IP_COMPUTE01='172.16.0.3'
BR_VXLAN_IP_INFRA='172.17.0.1'
BR_VXLAN_IP_COMPUTE00='172.17.0.2'
BR_VXLAN_IP_COMPUTE01='172.17.0.3'
NETWORK_CONTAINER='172.16.0.0/24'
NETWORK_TUNNEL='172.17.0.0/24'

if [ "$HOSTNAME" = "$HOSTNAME_INFRA" ]
then
  configure_ssh;
  configure_openstack_user_confi_yml;
  download_openstack;
  configure_openstack;

  #install_openstack;
else
  echo -e 'Procedimentos executados apenas na máquina Infra ...'
fi

