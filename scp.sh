#!/bin/bash

source parameters.conf

WHOAMI=$(whoami)
USER_HOME=$(eval echo "~$different_user")

rm -rf "$USER_HOME"/.ssh/*
ssh-keygen -t rsa -N "" -f "$USER_HOME"/.ssh/id_rsa
echo $'Host *
StrictHostKeyChecking no' > "$USER_HOME"/.ssh/config
chmod 400 /"$USER_HOME"/.ssh/config

printf '\n\e[1;33m%-6s\e[m\n' 'Accessing Infra0 Server...'
scp ./parameters.conf ./all_openstack_servers.sh ./only_infra_server.sh "$WHOAMI"@"$TEMP_IP_INFRA0":"$USER_HOME"/

printf '\n\e[1;33m%-6s\e[m\n' 'Accessing Compute00 Server...'
scp ./parameters.conf ./all_openstack_servers.sh "$WHOAMI"@"$TEMP_IP_COMPUTE00":"$USER_HOME"/

printf '\n\e[1;33m%-6s\e[m\n' 'Accessing Compute01 Server...'
scp ./parameters.conf ./all_openstack_servers.sh "$WHOAMI"@"$TEMP_IP_COMPUTE01":"$USER_HOME"/

printf '\n\e[1;33m%-6s\e[m\n' 'Accessing Compute02 Server...'
scp ./parameters.conf ./all_openstack_servers.sh "$WHOAMI"@"$TEMP_IP_COMPUTE02":"$USER_HOME"/

printf '\n\e[1;33m%-6s\e[m\n' 'Accessing rt-internet Router...'
scp ./parameters.conf ./rt-internet.sh "$WHOAMI"@"$TEMP_IP_RT_INTERNET":"$USER_HOME"/
