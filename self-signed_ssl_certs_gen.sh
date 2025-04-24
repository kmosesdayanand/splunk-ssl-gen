#!/bin/bash

#########################################################
# Author      : Moses Dayanand                          #
# Title       : OpenSSL Self Signed                     #
#               Certificate Generation Script           #
# Description : Creates Root CA, Server & Client Certs  #
#             : Verifies and organizes certs for Splunk #
# Version     : 1.0                                     #
#########################################################

# ==================================================
# 🎭 PART 1: Certificate Creation
# ==================================================

# Ask for password for protected keys
read -s -p "Enter password for server and client certificate (leave blank for no password): " server_password
echo

# Get current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Output directory setup
output_dir="$SCRIPT_DIR/Splunk_SSL_self_signed_Config"
cert_dir="$output_dir/Splunk_SSL_Certs"
conf_dir="$output_dir/local"

mkdir -p "$cert_dir"
mkdir -p "$conf_dir"

# Create Root CA key and certificate
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -days 3650 -out rootCA.pem

# Generate Server Key
if [ -z "$server_password" ]; then
    openssl genrsa -out server.key 2048
else
    openssl genrsa -aes256 -passout pass:"$server_password" -out server.key 2048
fi

# Generate Server CSR
openssl req -new -key server.key -out server.csr

# Sign Server Certificate
if [ -z "$server_password" ]; then
    openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.pem -days 3650
else
    openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.pem -days 3650 -passin pass:"$server_password"
fi

# Generate Client Key and CSR
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/C=US/ST=California/L=San Francisco/O=Splunk/OU=IT/CN=SplunkClient"

# Sign Client Certificate
openssl x509 -req -in client.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out client.pem -days 3650

# ==================================================
# ✅ PART 2: Validation and Verification
# ==================================================

# Match certificate and key moduli
openssl x509 -noout -modulus -in server.pem | openssl md5
openssl rsa -noout -modulus -in server.key | openssl md5

# Verify server and client certificates
openssl verify -CAfile rootCA.pem server.pem
openssl verify -CAfile rootCA.pem client.pem

# ==================================================
# ✨ PART 3: Magic — Bundling & Organizing
# ==================================================

# Duplicate server.pem as web_server.pem
cp server.pem "$cert_dir/web_server.pem"

# Create combined server.pem (cert + key)
cat server.pem server.key > "$cert_dir/server.pem"

# Create combined client.pem (cert + key)
cat client.pem client.key > "$cert_dir/client.pem"

# Copy private keys
cp server.key "$cert_dir/server.key"
cp client.key "$cert_dir/client.key"

# Create CA cert file (for Splunk trust)
cat rootCA.pem > "$cert_dir/ca_cert.pem"

# Create web.conf with filled password
cat > "$conf_dir/web.conf" <<EOF
[settings]
enableSplunkWebSSL = true
privKeyPath = \$SPLUNK_HOME/etc/apps/gen_ssl_splunk/Splunk_SSL_Certs/server.key
serverCert = \$SPLUNK_HOME/etc/apps/gen_ssl_splunk/Splunk_SSL_Certs/web_server.pem
sslPassword = $server_password
EOF

# Create server.conf with filled password
cat > "$conf_dir/server.conf" <<EOF
[sslConfig]
enableSplunkdSSL = true
cliVerifyServerName = false
sslVerifyServerName = false
serverCert = \$SPLUNK_HOME/etc/apps/gen_ssl_splunk/Splunk_SSL_Certs/server.pem
caCertFile = \$SPLUNK_HOME/etc/apps/gen_ssl_splunk/Splunk_SSL_Certs/ca_cert.pem
sslPassword = $server_password
EOF

# 🧹 Optional: Clean up raw certs from script dir
rm -f rootCA.srl rootCA.key rootCA.pem server.key server.csr server.pem server.serial client.key client.csr client.pem

# 🎉 Done
echo "✅ Certificate creation, bundling, and config generation complete!"
echo "📂 All outputs are neatly tucked into: $output_dir/"
