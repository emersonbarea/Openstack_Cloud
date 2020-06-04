#!/bin/bash

expiration() {
    printf '\n%s' 'Answer: how many days the certificate will be valid? (only number. Ex.: 30): '
    read expiration_days
    re='^[0-9]+$'
    if ! [[ $expiration_days =~ $re ]] ; then
        printf '\e[1;31m%-6s\e[m' 'error: Write only the number of days'
        expiration;
    fi
}

generate_userkey() {
    file="$BUILD_DIR"'/OpenVPN/users.conf'
    cd /root/EasyRSA-3.0.7/
    while IFS= read -r line
    do
        echo | bash ./easyrsa gen-req "$line" nopass
	cp /root/EasyRSA-3.0.7/pki/private/"$line".key /root/client-configs/keys/
	scp /root/EasyRSA-3.0.7/pki/reqs/"$line".req root@ca-server:/tmp
	ssh -tt root@ca-server << EOF
export EASYRSA_CERT_EXPIRE="$expiration_days"
cd /root/EasyRSA-3.0.7/
./easyrsa import-req /tmp/"$line".req "$line"
echo yes | bash ./easyrsa sign-req client "$line"
scp /root/EasyRSA-3.0.7/pki/issued/"$line".crt cesar@rt-internet.openstack.ita:/tmp
exit
EOF
       cp /tmp/"$line".crt /root/client-configs/keys/ 
       /root/cliet-configs/./make_config.sh "$line"
    done < "$file"
}

BUILD_DIR=$(pwd)

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi



expiration;
generate_userkey;
