#!/bin/bash

# Script from https://devopscube.com/create-self-signed-certificates-openssl/

echo "Generating a self-signed SSL certificate..."

DOMAIN="devopssampletesting"

sudo mkdir -p output 

# Create root CA & Private key

openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=${DOMAIN}/C=US/L=San Fransisco" \
            -keyout output/rootCA.key -out output/rootCA.crt 

# Generate Private key 

openssl genrsa -out output/${DOMAIN}.key 2048

# Create csf conf

cat > output/csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = San Fransisco
O = DevOps
OU = DevOps Platform
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}
IP.1 = 192.168.1.5 
IP.2 = 192.168.1.6

EOF

# create CSR request using private key

openssl req -new -key output/${DOMAIN}.key -out output/${DOMAIN}.csr -config output/csr.conf

# Create a external config file for the certificate

cat > output/cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}

EOF

# Create SSl with self signed CA

openssl x509 -req \
    -in output/${DOMAIN}.csr \
    -CA output/rootCA.crt -CAkey output/rootCA.key \
    -CAcreateserial -out output/${DOMAIN}.crt \
    -days 365 \
    -sha256 -extfile output/cert.conf

# Convert files to PEM format
sudo openssl x509 -in output/rootCA.crt -out output/rootCA.pem -outform PEM
sudo openssl x509 -in output/${DOMAIN}.crt -out output/${DOMAIN}.pem -outform PEM
sudo openssl rsa -in output/${DOMAIN}.key -out output/${DOMAIN}_private.pem -outform PEM

# copies all files to /etc/pki/syslog
sudo cp output/* /etc/pki/syslog/