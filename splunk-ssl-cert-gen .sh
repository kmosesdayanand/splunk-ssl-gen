#!/bin/bash

# Generate root CA key and certificate
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -days 3650 -out rootCA.pem

# Generate server key and certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.pem -days 3650


# Verification of Certificate
openssl x509 -noout -modulus -in server.pem | openssl md5
openssl rsa -noout -modulus -in server.key | openssl md5


# Making the Certifcates ready for Splunk Deployment
cat rootCA.pem > ca_cert.pem
cat server.pem > client.pem


#Verification of ca_cert.pem, server.pem and client.pem
openssl verify -CAfile rootCA.pem server.pem
openssl verify -CAfile ca_cert.pem server.pem
openssl verify -CAfile ca_cert.pem client.pem


echo "OpenSSL ccript executed successfully."