# CA-SERVER

wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz

cd ~
tar xvf EasyRSA-3.0.7.tgz
cd EasyRSA-3.0.7/
cp vars.example vars

sed -i -- 's/#set_var EASYRSA_REQ_COUNTRY	"US"/set_var EASYRSA_REQ_COUNTRY	"BR"/g' vars
sed -i -- 's/#set_var EASYRSA_REQ_PROVINCE	"California"/set_var EASYRSA_REQ_PROVINCE	"São Paulo"/g' vars
sed -i -- 's/#set_var EASYRSA_REQ_CITY	"San Francisco"/set_var EASYRSA_REQ_CITY	"São José dos Campos"/g' vars
sed -i -- 's/#set_var EASYRSA_REQ_ORG	"Copyleft Certificate Co"/set_var EASYRSA_REQ_ORG		"ITA"/g' vars
sed -i -- 's/#set_var EASYRSA_REQ_EMAIL	"me@example.net"/set_var EASYRSA_REQ_EMAIL	"cmarcondes@ita.br"/g' vars
sed -i -- 's/#set_var EASYRSA_REQ_OU		"My Organizational Unit"/set_var EASYRSA_REQ_OU		"CTA"/g' vars

./easyrsa init-pki

./easyrsa build-ca nopass


### EXECUTAR PASSO 1 DO SERVER


./easyrsa import-req /tmp/rt-internet.req rt-internet

./easyrsa sign-req server rt-internet

scp ~/EasyRSA-3.0.7/pki/issued/rt-internet.crt cesar@rt-internet.openstack.ita:/tmp
scp ~/EasyRSA-3.0.7/pki/ca.crt cesar@rt-internet.openstack.ita:/tmp

### EXECUTAR PASSO 2 DO SERVER

### EXECUTAR PASSO 3 DO SERVER (se tiver certificado de cliente para gerar)

cd ~/EasyRSA-3.0.7/
./easyrsa import-req /tmp/tocha.req tocha
./easyrsa sign-req client tocha
scp pki/issued/tocha.crt cesar@rt-internet.openstack.ita:/tmp

### EXECUTAR PASSO 4 NO SERVER

### EXECUTAR O PASSO 5 NO SERVER SE PRECISAR CONFIGURAR O OPENVPN NO SERVER

### EXECUTAR O PASSO 6 PARA CRIAR O ARQUIVO BASE PARA GERAR A CONFIGURAÇÃO DO CLIENTE

### EXECUTAR O PASSO 7 PARA GERAR A CONFIGURAÇÃO DO CLIENTE (Ex.: usuário Tocha)



