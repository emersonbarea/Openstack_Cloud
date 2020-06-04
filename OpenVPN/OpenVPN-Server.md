# OPENVPN

### INICIO PASSO 1 SERVER (EXECUTAR SOMENTE QUANDO SOLICITADO PELO CA-SERVER)

apt update
apt install openvpn -y

wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz

cd ~
tar xvf EasyRSA-3.0.7.tgz

 cd EasyRSA-3.0.7

./easyrsa init-pki

./easyrsa gen-req rt-internet nopass

cp ~/EasyRSA-3.0.7/pki/private/rt-internet.key /etc/openvpn/

scp ~/EasyRSA-3.0.7/pki/reqs/rt-internet.req root@192.168.201.252:/tmp

#### FIM PASSO 1 DO SERVER

#### INICIO PASSO 2 SERVER

cp /tmp/{rt-internet.crt,ca.crt} /etc/openvpn/

cd ~/EasyRSA-3.0.7

./easyrsa gen-dh

openvpn --genkey --secret ta.key

cp ~/EasyRSA-3.0.7/ta.key /etc/openvpn/
cp ~/EasyRSA-3.0.7/pki/dh.pem /etc/openvpn/

#### FIM PASSO 2 SERVER

#### INICIO PASSO 3 SERVER (Gerando um certificado de usuário cliente e um par de chaves)

mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
cd ~/EasyRSA-3.0.7
./easyrsa gen-req tocha nopass
cp pki/private/tocha.key ~/client-configs/keys/

scp pki/reqs/tocha.req root@192.168.201.252:/tmp

#### FIM PASSO 3 SERVER

#### INICIO PASSO 4 SERVER

cp /tmp/tocha.crt ~/client-configs/keys/
cp ~/EasyRSA-3.0.7/ta.key ~/client-configs/keys/
cp /etc/openvpn/ca.crt ~/client-configs/keys/

#### FIM PASSO 4 SERVER

#### PASSO 5 NO SERVER
#CONFIGURANDO O SEVIDOR VPN
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
gzip -d /etc/openvpn/server.conf.gz
sed -i -- 's/cipher AES-256-CBC/cipher AES-256-CBC\nauth SHA256/g' /etc/openvpn/server.conf
sed -i -- 's/dh dh2048.pem/dh dh.pem/g' /etc/openvpn/server.conf
sed -i -- 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
sed -i -- 's/;group nogroup/group nogroup/g' /etc/openvpn/server.conf
sed -i -- 's/cert server.crt/cert rt-internet.crt/g' /etc/openvpn/server.conf
sed -i -- 's/key server.key/key rt-internet.key/g' /etc/openvpn/server.conf

systemctl start openvpn@server
systemctl enable openvpn@server

#### FIM PASSO 5

#### INICIO PASSO 6 (CONFIGURANDO O ACESSO DO USUÁRIO)

mkdir -p ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
sed -i -- 's/remote my-server-1 1194/remote 192.168.15.168 1194/g' ~/client-configs/base.conf
sed -i -- 's/;user nobody/user nobody/g' ~/client-configs/base.conf
sed -i -- 's/;group nogroup/group nogroup/g' ~/client-configs/base.conf
sed -i -- 's/ca ca.crt/#ca ca.crt/g' ~/client-configs/base.conf
sed -i -- 's/cert client.crt/#cert client.crt/g' ~/client-configs/base.conf
sed -i -- 's/key client.key/#key client.key/g' ~/client-configs/base.conf
sed -i -- 's/tls-auth ta.key 1/#tls-auth ta.key 1/g' ~/client-configs/base.conf
sed -i -- 's/cipher AES-256-CBC/cipher AES-256-CBC\nauth SHA256\nkey-direction 1\n# script-security 2\n# up \/etc\/openvpn\/update-resolv-conf\n# down \/etc\/openvpn\/update-resolv-conf/g' ~/client-configs/base.conf

cp ~/Openstack_Cloud/OpenVPN/make_config.sh ~/client-configs/make_config.sh

chmod 700 ~/client-configs/make_config.sh

#### FIM PASSO 6

#### INICIO PASSO 7 (GERAR CONFIGURAÇÃO DO USUÁRIO Tocha)

./make_config.sh tocha
ls ~/client-configs/files/tocha.ovpn

-> passar esse arquivo para o cliente
-> apt install openvpn
-> sudo openvpn --config client1.ovpn

