#!/bin/bash

configure_lvm() {
  vgremove "$CINDER_VOLUME" 2> /dev/null
  pvremove "$MOUNT_POINT" 2> /dev/null
  pvcreate --metadatasize 2048 "$MOUNT_POINT"
  vgcreate "$CINDER_VOLUME" "$MOUNT_POINT"
}

configure_ssh() {
  printf '\n\e[1;33m%-6s\e[m\n' 'Configuring Infra00...'
  printf '[sudo] senha para '$WHOAMI':'
  read -s PASSWORD
  echo ""
  sudo passwd root
  sed -i -- 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
  systemctl restart ssh
  rm -rf /root/.ssh 2> /dev/null
  mkdir /root/.ssh
  ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
  echo -e 'Host *
  StrictHostKeyChecking no' > /root/.ssh/config
  chmod 400 /root/.ssh/config

  apt install sshpass -y

  for (( c=1; c<=$COMPUTES_NUM; c++ )); do
      cat /root/.ssh/id_rsa.pub | sudo tee --append /root/.ssh/authorized_keys; done
 
  for i in $(sudo cat -n /root/.ssh/authorized_keys | awk '{print $1}'); do
	  sudo sed -Ei "${i}s/@.*/@compute0$(($i - 1))/" /root/.ssh/authorized_keys; done

  cat /root/.ssh/id_rsa.pub | sudo tee --append /root/.ssh/authorized_keys

  printf '\n\e[1;33m%-6s\e[m\n' 'Configuring Compute00...'
  sshpass -p "$PASSWORD" ssh -t "$CURRENT_USER"@"$IP_INTERNET_COMPUTE00" "echo "$PASSWORD" | sudo -S rm -rf "$HOME_DIR"/.ssh/; exit"
  sshpass -p "$PASSWORD" scp -r /root/.ssh "$CURRENT_USER"@"$IP_INTERNET_COMPUTE00":"$HOME_DIR"/
  sshpass -p "$PASSWORD" ssh -t "$CURRENT_USER"@"$IP_INTERNET_COMPUTE00" "echo "$PASSWORD" | sudo -S rm -rf /root/.ssh/; sudo mkdir /root/.ssh/; sudo cp "$HOME_DIR"/.ssh/* /root/.ssh/; sudo sed -i -- 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config; sudo systemctl restart ssh; echo""; sudo passwd root; exit"

  printf '\n\e[1;33m%-6s\e[m\n' 'Configuring Compute01...'
  sshpass -p "$PASSWORD" ssh -t "$CURRENT_USER"@"$IP_INTERNET_COMPUTE01" "echo "$PASSWORD" | sudo -S rm -rf "$HOME_DIR"/.ssh/; exit"
  sshpass -p "$PASSWORD" scp -r /root/.ssh "$CURRENT_USER"@"$IP_INTERNET_COMPUTE01":"$HOME_DIR"/
  sshpass -p "$PASSWORD" ssh -t "$CURRENT_USER"@"$IP_INTERNET_COMPUTE01" "echo "$PASSWORD" | sudo -S rm -rf /root/.ssh/; sudo mkdir /root/.ssh/; sudo cp "$HOME_DIR"/.ssh/* /root/.ssh/; sudo sed -i -- 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config; sudo systemctl restart ssh; echo""; sudo passwd root; exit"

  printf '\n\e[1;33m%-6s\e[m\n' 'Configuring Compute02...'
  sshpass -p "$PASSWORD" ssh -t "$CURRENT_USER"@"$IP_INTERNET_COMPUTE02" "echo "$PASSWORD" | sudo -S rm -rf "$HOME_DIR"/.ssh/; exit"
  sshpass -p "$PASSWORD" scp -r /root/.ssh "$CURRENT_USER"@"$IP_INTERNET_COMPUTE02":"$HOME_DIR"/
  sshpass -p "$PASSWORD" ssh -t "$CURRENT_USER"@"$IP_INTERNET_COMPUTE02" "echo "$PASSWORD" | sudo -S rm -rf /root/.ssh/; sudo mkdir /root/.ssh/; sudo cp "$HOME_DIR"/.ssh/* /root/.ssh/; sudo sed -i -- 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config; sudo systemctl restart ssh; echo""; sudo passwd root; exit"

  printf '\n\e[1;33m%-6s\e[m\n' 'Testing ssh direct connection to servers...'
  ssh root@"$IP_MGMT_INFRA0" 'exit'
  ssh root@"$IP_MGMT_COMPUTE00" 'exit'
  ssh root@"$IP_MGMT_COMPUTE01" 'exit'
  ssh root@"$IP_MGMT_COMPUTE02" 'exit'
  ssh root@"$IP_TENANT_INFRA0" 'exit'
  ssh root@"$IP_TENANT_COMPUTE00" 'exit'
  ssh root@"$IP_TENANT_COMPUTE01" 'exit'
  ssh root@"$IP_TENANT_COMPUTE02" 'exit'
  ssh root@"$IP_STORAGE_INFRA0" 'exit'
  ssh root@"$IP_STORAGE_COMPUTE00" 'exit'
  ssh root@"$IP_STORAGE_COMPUTE01" 'exit'
  ssh root@"$IP_STORAGE_COMPUTE02" 'exit'
}

download_openstack() {
  rm -rf /opt/openstack-ansible 2> /dev/null
  git clone -b 18.1.1 https://git.openstack.org/openstack/openstack-ansible /opt/openstack-ansible
}

configure_openstack_user_confi_yml() {
  rm -rf "$BUILD_DIR"/openstack_user_config.yml 2> /dev/null
  echo -e '# Host IPs:
# infra0_public_addr   = '$IP_INTERNET_INFRA0'
# compute00_public_addr   = '$IP_INTERNET_COMPUTE00'
# compute01_public_addr   = '$IP_INTERNET_COMPUTE01'
# compute02_public_addr   = '$IP_INTERNET_COMPUTE02'

cidr_networks:
  container: '$NETWORK_MGMT'/'$PREFIX_LENGTH_MGMT'
  tunnel: '$NETWORK_TENANT'/'$PREFIX_LENGTH_TENANT'
  storage: '$NETWORK_STORAGE'/'$PREFIX_LENGTH_STORAGE'

used_ips:
  - '$IP_INTERNET_INFRA0'
  - '$IP_INTERNET_COMPUTE00'
  - '$IP_INTERNET_COMPUTE01'
  - '$IP_INTERNET_COMPUTE02'
  - '$IP_MGMT_INFRA0'
  - '$IP_MGMT_COMPUTE00'
  - '$IP_MGMT_COMPUTE01'
  - '$IP_MGMT_COMPUTE02'
  - '$IP_TENANT_INFRA0'
  - '$IP_TENANT_COMPUTE00'
  - '$IP_TENANT_COMPUTE01'
  - '$IP_TENANT_COMPUTE02'
  - '$IP_STORAGE_INFRA0'
  - '$IP_STORAGE_COMPUTE00'
  - '$IP_STORAGE_COMPUTE01'
  - '$IP_STORAGE_COMPUTE02'

global_overrides:
  internal_lb_vip_address: '$IP_MGMT_INFRA0'
  external_lb_vip_address: '$IP_INTERNET_INFRA0'
  management_bridge: "'$OVS_BRIDGE_MGMT'"
  provider_networks:
    - network:
        container_bridge: "'$OVS_BRIDGE_MGMT'"
        container_type: "veth"
        container_interface: "eth1"
        ip_from_q: "container"
        type: "raw"
        group_binds:
          - all_containers
          - hosts
        is_container_address: true
    - network:
        container_bridge: "'$OVS_BRIDGE_TENANT'"
        container_type: "veth"
        container_interface: "eth10"
        ip_from_q: "tunnel"
        type: "vxlan"
        range: "1:1000"
        net_name: "'$OPENSTACK_VXLAN_NETWORK'"
        group_binds:
          - neutron_linuxbridge_agent
    - network:
        group_binds:
          - neutron_linuxbridge_agent
        container_bridge: "'$BOND'.'$VLAN_TAG_INTERNET_VM'"
        container_type: "veth"
        container_interface: "eth11"
        type: "flat"
        net_name: "'$OPENSTACK_EXTERNAL_NETWORK'"
    - network:
        container_bridge: "'$OVS_BRIDGE_STORAGE'"
        container_type: "veth"
        container_interface: "eth2"
        ip_from_q: "storage"
        type: "raw"
        group_binds:
          - glance_api
          - cinder_api
          - cinder_volume
          - nova_compute

###
### Infrastructure
###

# galera, memcache, rabbitmq, utility
shared-infra_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# repository (apt cache, python packages, etc)
repo-infra_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# load balancer
haproxy_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

###
### OpenStack
###

# keystone
identity_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# cinder api services
storage-infra_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# glance
image_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# nova api, conductor, etc services
compute-infra_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# heat
orchestration_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# horizon
dashboard_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# neutron server, agents (L3, etc)
network_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0'

# nova hypervisors
compute_hosts:
  compute00:
    ip: '$IP_MGMT_COMPUTE00'
  compute01:
    ip: '$IP_MGMT_COMPUTE01'
  compute02:
    ip: '$IP_MGMT_COMPUTE02'

# cinder storage host (LVM-backed)
storage_hosts:
  infra:
    ip: '$IP_MGMT_INFRA0' 
    container_vars:
      cinder_backends:
        limit_container_types: cinder_volume
        lvm:
          volume_group: cinder-volumes
          volume_driver: cinder.volume.drivers.lvm.LVMVolumeDriver
          volume_backend_name: LVM_iSCSI
          iscsi_ip_address: "'$IP_STORAGE_INFRA0'"' > "$BUILD_DIR"/openstack_user_config.yml
}

configure_openstack() {
  rm -rf /etc/openstack_deploy 2> /dev/null
  cd /opt/openstack-ansible
  git checkout -b 18.1.1 18.1.1
  ./scripts/bootstrap-ansible.sh
  cp -R etc/openstack_deploy /etc/
  cp "$HOME_DIR"/openstack_user_config.yml /etc/openstack_deploy/openstack_user_config.yml
  echo -e 'install_method: "source"
galera_monitoring_allowed_source: "0.0.0.0/0"
neutron_l2_population: "true"
lxc_cache_prep_timeout: 2700' >  /etc/openstack_deploy/user_variables.yml
  ./scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml
}

install_openstack() {
  cd /opt/openstack-ansible/playbooks/
  openstack-ansible setup-infrastructure.yml --syntax-check
  openstack-ansible setup-hosts.yml
  openstack-ansible setup-infrastructure.yml
  openstack-ansible setup-openstack.yml
}


source parameters.conf

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

HOSTNAME=$(hostname)
BUILD_DIR=$(pwd)
CURRENT_USER=${SUDO_USER:-${USER}}
HOME_DIR=$(eval echo "~$different_user")

if [ "$HOSTNAME" = "$HOSTNAME_INFRA0" ]
then
  configure_lvm;
  configure_ssh;
  configure_openstack_user_confi_yml;
  download_openstack;
  configure_openstack;

  install_openstack;
else
  echo -e 'Execute only on Infra0 server ...'
fi
