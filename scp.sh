#!/bin/bash

source parameters.conf

WHOAMI=$(whoami)
USER_HOME=$(eval echo "~$different_user")

rm -rf "$USER_HOME"/.ssh/*
ssh-keygen -t rsa -N "" -f "$USER_HOME"/.ssh/id_rsa
ssh-keygen -f "$USER_HOME"/.ssh/id_rsa -e -m pem
echo $'Host *
StrictHostKeyChecking no' > "$USER_HOME"/.ssh/config
chmod 400 /"$USER_HOME"/.ssh/config

echo '
Accessing Infra0 Server...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./all_openstack_servers.sh ./only_infra_server.sh "$WHOAMI"@"$TEMP_IP_INFRA0":"$USER_HOME"/

echo '
Accessing Compute00 Server...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./all_openstack_servers.sh "$WHOAMI"@"$TEMP_IP_COMPUTE00":"$USER_HOME"/

echo '
Accessing Compute01 Server...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./all_openstack_servers.sh "$WHOAMI"@"$TEMP_IP_COMPUTE01":"$USER_HOME"/

echo '
Accessing Compute02 Server...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./all_openstack_servers.sh "$WHOAMI"@"$TEMP_IP_COMPUTE02":"$USER_HOME"/

echo '
Accessing sw-internet Switch...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./sw-internet_first_of_all.sh ./sw-internet.sh "$WHOAMI"@"$TEMP_IP_SW_INTERNET":"$USER_HOME"/

echo '
Accessing sw-mgmt Switch...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./sw-mgmt.sh "$WHOAMI"@"$TEMP_IP_SW_MGMT":"$USER_HOME"/

echo '
Accessing sw-tenant Switch...
'
scp -i "$USER_HOME"/.ssh/id_rsa.pub ./parameters.conf ./sw-tenant.sh "$WHOAMI"@"$TEMP_IP_SW_TENANT":"$USER_HOME"/
