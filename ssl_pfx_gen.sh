#!/bin/bash

set -e  # Stop on error

mkdir -p /root/ssl-chain/{root,intermediate,leaf}
cd /root/ssl-chain

### === 1. ROOT CA === ###
echo "🔧 Step 1: Creating the Root Certificate Authority (Root CA)..."

echo "➡️  Generating a 4096-bit encrypted private key for Root CA..."
openssl genpkey -algorithm RSA -aes256 -out root/rootCA.key -pkeyopt rsa_keygen_bits:4096
echo "✅ Root private key generated: root/rootCA.key"

echo "➡️  Creating a self-signed Root CA certificate valid for 10 years..."
openssl req -x509 -new -key root/rootCA.key -sha256 -days 3650 \
  -out root/rootCA.crt
echo "✅ Self-signed Root CA certificate created: root/rootCA.crt"

### === 2. INTERMEDIATE CA === ###
echo "🔧 Step 2: Creating the Intermediate Certificate Authority (Intermediate CA)..."

echo "➡️  Generating a 4096-bit encrypted private key for Intermediate CA..."
openssl genpkey -algorithm RSA -aes256 -out intermediate/intermediateCA.key -pkeyopt rsa_keygen_bits:4096
echo "✅ Intermediate private key generated: intermediate/intermediateCA.key"

echo "➡️  Creating a Certificate Signing Request (CSR) for Intermediate CA..."
openssl req -new -key intermediate/intermediateCA.key \
  -out intermediate/intermediateCA.csr
echo "✅ Intermediate CA CSR created: intermediate/intermediateCA.csr"

echo "➡️  Signing the Intermediate CA certificate with the Root CA..."
openssl x509 -req -in intermediate/intermediateCA.csr \
  -CA root/rootCA.crt -CAkey root/rootCA.key -CAcreateserial \
  -out intermediate/intermediateCA.crt -days 1825 -sha256
echo "✅ Intermediate certificate signed by Root CA: intermediate/intermediateCA.crt"

### === 3. LEAF CERTIFICATE === ###
echo "🔧 Step 3: Creating the Leaf Certificate (Client/Server Cert)..."

echo "➡️  Generating a 2048-bit encrypted private key for Leaf certificate..."
openssl genpkey -algorithm RSA -aes256 -out leaf/leaf.key -pkeyopt rsa_keygen_bits:2048
echo "✅ Leaf private key generated: leaf/leaf.key"

echo "➡️  Creating a Certificate Signing Request (CSR) for the Leaf cert..."
openssl req -new -key leaf/leaf.key \
  -out leaf/leaf.csr
echo "✅ Leaf CSR created: leaf/leaf.csr"

echo "➡️  Signing the Leaf certificate with the Intermediate CA..."
openssl x509 -req -in leaf/leaf.csr \
  -CA intermediate/intermediateCA.crt -CAkey intermediate/intermediateCA.key -CAcreateserial \
  -out leaf/leaf.crt -days 825 -sha256
echo "✅ Leaf certificate signed by Intermediate CA: leaf/leaf.crt"

### === 4. CA BUNDLE === ###
echo "🔧 Step 4: Creating a CA bundle for validation chain..."

echo "➡️  Concatenating Intermediate and Root CA certificates into one bundle..."
cat intermediate/intermediateCA.crt root/rootCA.crt > leaf/ca_bundle.crt
echo "✅ CA Bundle created: leaf/ca_bundle.crt"

### === 5. CREATE PFX FILE === ###
echo "🔧 Step 5: Creating a password-protected .pfx (PKCS#12) bundle..."

echo "🔐 Enter password for .pfx bundle:"
read -s PFX_PASS

echo "➡️  Creating the .pfx file containing private key, certificate, and CA bundle..."
openssl pkcs12 -export \
  -out leaf/leaf.pfx \
  -inkey leaf/leaf.key \
  -in leaf/leaf.crt \
  -certfile leaf/ca_bundle.crt \
  -passout pass:"$PFX_PASS"
echo "✅ .pfx file created: leaf/leaf.pfx"

echo "🎉 All done! Your certificates are ready at: /root/ssl-chain/leaf"
