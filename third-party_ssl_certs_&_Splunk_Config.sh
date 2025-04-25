#!/bin/bash

# Prompt for certificate and key paths
echo "Enter the path to your Server Certificate:"
read SERVER_CERT_SRC

echo "Enter the path to your Private Key:"
read PRIVATE_KEY_SRC

echo "Enter the path to your Root Certificate:"
read ROOT_CERT_SRC

echo "Enter the path to your Intermediate Certificate (Level 1):"
read INTERMEDIATE1_CERT_SRC

echo "Enter the path to your Intermediate Certificate (Level 2, optional – press Enter to skip):"
read INTERMEDIATE2_CERT_SRC

# Prompt for private key password once
echo "Enter password to protect the private key (used in web.conf, inputs.conf, and outputs.conf):"
read -s key_password

# Set directory structure
BASE_DIR="third-party_ssl_certs_&_Splunk_Config"
CERTS_DIR="${BASE_DIR}/certs"
CONF_DIR="${BASE_DIR}/local"

mkdir -p "$CERTS_DIR"
mkdir -p "$CONF_DIR"

# Copy certs and key to destination directory
cp "$SERVER_CERT_SRC" "$CERTS_DIR/server-cert.pem"
cp "$SERVER_CERT_SRC" "$CERTS_DIR/client-cert.pem"
cp "$SERVER_CERT_SRC" "$CERTS_DIR/web_server-cert.pem"
cp "$PRIVATE_KEY_SRC" "$CERTS_DIR/private-key.pem"

# Build combined cert chain
COMBINED_CERT="${CERTS_DIR}/combined-cert.pem"
if [ -n "$INTERMEDIATE2_CERT_SRC" ]; then
    cat "$ROOT_CERT_SRC" "$INTERMEDIATE1_CERT_SRC" "$INTERMEDIATE2_CERT_SRC" "$SERVER_CERT_SRC" > "$COMBINED_CERT"
else
    cat "$ROOT_CERT_SRC" "$INTERMEDIATE1_CERT_SRC" "$SERVER_CERT_SRC" > "$COMBINED_CERT"
fi

# Concatenate cert + key pairs
cat "$CERTS_DIR/server-cert.pem" "$CERTS_DIR/private-key.pem" > "$CERTS_DIR/server-cert+privatekey.pem"
cat "$CERTS_DIR/client-cert.pem" "$CERTS_DIR/private-key.pem" > "$CERTS_DIR/client-cert+privatekey.pem"

# ========== Generate Splunk Configs ==========

# web.conf
cat > "$CONF_DIR/web.conf" <<EOF
[settings]
enableSplunkWebSSL = true
privKeyPath = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/private-key.pem
serverCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/web_server-cert.pem
sslPassword = $key_password
EOF

# inputs.conf
cat > "$CONF_DIR/inputs.conf" <<EOF
[SSL]
serverCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/server-cert.pem
sslPassword = $key_password
requireClientCert = false
EOF

# outputs.conf
cat > "$CONF_DIR/outputs.conf" <<EOF
[tcpout:<group_name>]
clientCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/client-cert.pem
sslPassword = $key_password
EOF

# server.conf (no password required)
cat > "$CONF_DIR/server.conf" <<EOF
[sslConfig]
enableSplunkdSSL = true
cliVerifyServerName = false
sslVerifyServerName = false
serverCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/server-cert.pem
caCertFile = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/combined-cert.pem
EOF

# Final tree structure output
echo ""
echo "✅ All files generated successfully!"
echo "📁 Directory structure:"
tree "$BASE_DIR"
