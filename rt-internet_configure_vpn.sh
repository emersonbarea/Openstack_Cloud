#!/bin/bash

configure_vpn() {
    rm -rf "$HOME_DIR"/EasyRSA-3.0.7* 2> /dev/null
    wget -P "$HOME_DIR"/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz
    tar xvf "$HOME_DIR"/EasyRSA-3.0.7.tgz -C "$HOME_DIR"
    rm -rf "$HOME_DIR"/EasyRSA-3.0.7.tgz 2> /dev/null
    mv "$HOME_DIR"/EasyRSA-3.0.7/vars.example "$HOME_DIR"/EasyRSA-3.0.7/vars
    echo 'set_var EASYRSA_PKI		"'$HOME_DIR'/pki"' >> "$HOME_DIR"/EasyRSA-3.0.7/vars
    "$HOME_DIR"/EasyRSA-3.0.7/./easyrsa init-pki
    echo | bash "$HOME_DIR"/EasyRSA-3.0.7/./easyrsa gen-req "$HOSTNAME_RT_INTERNET" nopass
    cp "$HOME_DIR"/pki/private/"$HOSTNAME_RT_INTERNET".key /etc/openvpn/
    scp "$HOME_DIR"/pki/reqs/"$HOSTNAME_RT_INTERNET".req root@ca-server:/tmp
    ssh -tt root@ca-server << EOF
cd /root/EasyRSA-3.0.7/
echo yes | bash ./easyrsa revoke rt-internet
./easyrsa import-req /tmp/"$HOSTNAME_RT_INTERNET".req "$HOSTNAME_RT_INTERNET"
echo yes | bash ./easyrsa sign-req server "$HOSTNAME_RT_INTERNET"
scp /root/EasyRSA-3.0.7/pki/issued/"$HOSTNAME_RT_INTERNET".crt huguinho@rt-internet.openstack.ita:/tmp
scp /root/EasyRSA-3.0.7/pki/ca.crt huguinho@rt-internet.openstack.ita:/tmp
exit
EOF
    cp /tmp/{"$HOSTNAME_RT_INTERNET".crt,ca.crt} /etc/openvpn/
    "$HOME_DIR"/EasyRSA-3.0.7/./easyrsa gen-dh
    openvpn --genkey --secret "$HOME_DIR"/pki/ta.key
    cp "$HOME_DIR"/pki/ta.key /etc/openvpn/
    cp "$HOME_DIR"/pki/dh.pem /etc/openvpn/

    cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
    gzip -d /etc/openvpn/server.conf.gz
    sed -i -- 's/cipher AES-256-CBC/cipher AES-256-CBC\nauth SHA256/g' /etc/openvpn/server.conf
    sed -i -- 's/dh dh2048.pem/dh dh.pem/g' /etc/openvpn/server.conf
    sed -i -- 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
    sed -i -- 's/;group nogroup/group nogroup/g' /etc/openvpn/server.conf
    sed -i -- 's/cert server.crt//g' /etc/openvpn/server.conf
    echo "" >> /etc/openvpn/server.conf
    echo "cert $HOSTNAME_RT_INTERNET.crt" >> /etc/openvpn/server.conf
    sed -i -- 's/key server.key//g' /etc/openvpn/server.conf
    echo "key $HOSTNAME_RT_INTERNET.key" >> /etc/openvpn/server.conf
    sed -i -- 's/server 10.8.0.0 255.255.255.0//g' /etc/openvpn/server.conf
    echo "server $NETWORK_VPN_NET_VM $MASK_VPN_NET_VM" >> /etc/openvpn/server.conf
    echo 'push "route '$NETWORK_INTERNET' '$MASK_INTERNET'"' >> /etc/openvpn/server.conf
    echo 'push "route '$NETWORK_INTERNET_ADMIN' '$MASK_INTERNET_ADMIN'"' >> /etc/openvpn/server.conf
    echo 'push "route '$NETWORK_INTERNET_VM' '$MASK_INTERNET_VM'"' >> /etc/openvpn/server.conf
    echo "client-config-dir ccd" >> /etc/openvpn/server.conf
    echo "route $NETWORK_VPN_NET_ADMIN $MASK_VPN_NET_ADMIN" >> /etc/openvpn/server.conf

    rm -rf /etc/openvpn/ccd 2> /dev/null
    mkdir -p /etc/openvpn/ccd
    IP_VPN=$(echo "$NETWORK_VPN_NET_ADMIN" | cut -d"." -f 1,2,3)
    echo "ifconfig-push $IP_VPN.1 $IP_VPN.2" > /etc/openvpn/ccd/"Hugo Junqueira"
    echo "ifconfig-push $IP_VPN.5 $IP_VPN.6" > /etc/openvpn/ccd/"Julicleido Antunes"

    mkdir -p "$HOME_DIR"/client-configs/keys 2> /dev/null
    chmod -R 700 "$HOME_DIR"/client-configs
    cp /etc/openvpn/ta.key "$HOME_DIR"/client-configs/keys/
    cp /etc/openvpn/ca.crt "$HOME_DIR"/client-configs/keys/

    mkdir -p "$HOME_DIR"/client-configs/files 2> /dev/null
    cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/remote my-server-1 1194//g' "$HOME_DIR"/client-configs/base.conf
    echo "remote $OUTSIDE_IP 1194" >> "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/;user nobody/user nobody/g' "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/;group nogroup/group nogroup/g' "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/ca ca.crt/#ca ca.crt/g' "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/cert client.crt/#cert client.crt/g' "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/key client.key/#key client.key/g' "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/tls-auth ta.key 1/#tls-auth ta.key 1/g' "$HOME_DIR"/client-configs/base.conf
    sed -i -- 's/cipher AES-256-CBC/cipher AES-256-CBC\nauth SHA256\nkey-direction 1\n# script-security 2\n# up \/etc\/openvpn\/update-resolv-conf\n# down \/etc\/openvpn\/update-resolv-conf/g' "$HOME_DIR"/client-configs/base.conf

    echo '#!/bin/bash

# First argument: Client identifier

KEY_DIR='"$HOME_DIR"'/client-configs/keys
OUTPUT_DIR='"$HOME_DIR"'/client-configs/files
BASE_CONFIG='"$HOME_DIR"'/client-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e "<ca>") \
    ${KEY_DIR}/ca.crt \
    <(echo -e "</ca>\n<cert>") \
    ${KEY_DIR}/"${1}".crt \
    <(echo -e "</cert>\n<key>") \
    ${KEY_DIR}/"${1}".key \
    <(echo -e "</key>\n<tls-auth>") \
    ${KEY_DIR}/ta.key \
    <(echo -e "</tls-auth>") \
    > ${OUTPUT_DIR}/"${1}".ovpn' > "$HOME_DIR"/client-configs/make_config.sh

    chmod 700 "$HOME_DIR"/client-configs/make_config.sh

    systemctl restart openvpn@server
    systemctl enable openvpn@server
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

source parameters.conf

HOME_DIR=$(eval echo "~$different_user")

configure_vpn;
