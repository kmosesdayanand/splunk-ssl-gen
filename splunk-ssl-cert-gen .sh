#!/bin/bash

# Generate root CA key and certificate
echo "Generating root CA key..."
openssl genrsa -out rootCA.key 2048
echo "Generating root CA certificate..."
openssl req -x509 -new -nodes -key rootCA.key -days 3650 -out rootCA.pem

# Generate server key and certificate
echo "Generating server key..."
openssl genrsa -out server.key 2048
echo "Generating server certificate request..."
openssl req -new -key server.key -out server.csr
echo "Signing server certificate request..."
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.pem -days 3650

# Verification of Certificate
echo "Verifying server certificate modulus..."
openssl x509 -noout -modulus -in server.pem | openssl md5
echo "Verifying server key modulus..."
openssl rsa -noout -modulus -in server.key | openssl md5

# Making the Certifcates ready for Splunk Deployment
echo "Creating ca_cert.pem..."
cat rootCA.pem > ca_cert.pem
echo "Creating client.pem..."
cat server.pem > client.pem

# Verification of ca_cert.pem, server.pem and client.pem
echo "Verifying server.pem with rootCA.pem..."
openssl verify -CAfile rootCA.pem server.pem
echo "Verifying server.pem with ca_cert.pem..."
openssl verify -CAfile ca_cert.pem server.pem
echo "Verifying client.pem with ca_cert.pem..."
openssl verify -CAfile ca_cert.pem client.pem

echo "OpenSSL script executed successfully."