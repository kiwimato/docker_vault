#!/bin/bash
# A script that generates a CA and server & client keypairs for local dev purposes
# by kiwimato

if [ -z $SAN ]
  then echo "Set SAN with a DNS or IP(e.g. export SAN=IP.1:127.0.0.1,IP.2:172.18.0.2)."
  exit 1
fi

echo "Creating CA, server cert/key, and client cert/key..."

echo "Creating basic files/directories"
cd tls
mkdir {certs,crl,newcerts}
touch index.txt
echo 1000 > serial

echo "CA private key (unencrypted)"
openssl genrsa -out ca.key 4096
echo "Certificate Authority (self-signed certificate)"
openssl req -config openssl.conf -new -x509 -days 3650 -sha256 -key ca.key -extensions v3_ca -out ca.crt -subj "/CN=selfsigned-ca"

echo "Server private key (unencrypted)"
openssl genrsa -out server.key 4096
echo "Server certificate signing request (CSR)"
openssl req -config openssl.conf -new -sha256 -key server.key -out server.csr -subj "/CN=selfsigned-server"
echo "Certificate Authority signs CSR to grant a certificate"
openssl ca -batch -config openssl.conf -extensions server_cert -days 1825 -notext -md sha256 -in server.csr -out server.crt -cert ca.crt -keyfile ca.key

echo "Client private key (unencrypted)"
openssl genrsa -out client.key 4096
echo "Signed client certificate signing request (CSR)"
openssl req -config openssl.conf -new -sha256 -key client.key -out client.csr -subj "/CN=system:etcd-peer:etcd1"
echo "Certificate Authority signs CSR to grant a certificate"
openssl ca -batch -config openssl.conf -extensions usr_cert -days 1825 -notext -md sha256 -in client.csr -out client.crt -cert ca.crt -keyfile ca.key

[[ -d ../config ]] && cp server.crt server.key ../config
echo "SSL Chain to save & import into your system (optional)"
cat ca.crt ../config/server.crt > fullchain.crt

rm -f index.* serial* *.csr
rm -rf crl