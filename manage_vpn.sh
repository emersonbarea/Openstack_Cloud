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
    while IFS= read -r line
    do
        echo | bash "$HOME_DIR"/EasyRSA-3.0.7/./easyrsa gen-req "$line" nopass
	cp "$HOME_DIR"/pki/private/"$line".key "$HOME_DIR"/client-configs/keys/
	scp "$HOME_DIR"/pki/reqs/"$line".req root@ca-server:/tmp
	ssh -tt root@ca-server << EOF
export EASYRSA_CERT_EXPIRE="$expiration_days"
cd /root/EasyRSA-3.0.7/
./easyrsa revoke $line
./easyrsa import-req /tmp/"$line".req "$line"
echo yes | bash ./easyrsa sign-req client "$line"
scp /root/EasyRSA-3.0.7/pki/issued/"$line".crt cesar@rt-internet.openstack.ita:/tmp
exit
EOF
       cp /tmp/"$line".crt "$HOME_DIR"/client-configs/keys/ 
       "$HOME_DIR"/client-configs/./make_config.sh "$line"
    done < "$file"
}

BUILD_DIR=$(pwd)
HOME_DIR=$(eval echo "~$different_user")

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

expiration;
generate_userkey;
