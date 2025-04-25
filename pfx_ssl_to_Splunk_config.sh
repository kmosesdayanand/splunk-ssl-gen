#!/bin/bash

# Ask for PFX file path and password
echo "Enter the path to your PFX file (e.g., server.pfx):"
read PFX_FILE

echo "Enter the password for the PFX file (will be used for both server and client certs):"
read -s PASSWORD

# Use same password for client and server key encryption
server_password=$PASSWORD
client_password=$PASSWORD

# Ask for intermediate and root certificate paths
echo "Enter the path to your intermediate certificate (Level 1):"
read INTERMEDIATE1_CERT

echo "Enter the path to your intermediate certificate (Level 2, optional - press Enter to skip):"
read INTERMEDIATE2_CERT

echo "Enter the path to your root certificate:"
read ROOT_CERT

# Set directory structure
BASE_DIR="pfx_ssl_to_Splunk_config"
CERTS_DIR="${BASE_DIR}/certs"
CONF_DIR="${BASE_DIR}/local"

mkdir -p "$CERTS_DIR"
mkdir -p "$CONF_DIR"

# Output cert/key paths
SERVER_CERT_PEM="${CERTS_DIR}/server-cert.pem"
PRIVATE_KEY_PEM="${CERTS_DIR}/private-key.pem"
COMBINED_CERT="${CERTS_DIR}/combined-cert.pem"
WEB_SERVER_CERT="${CERTS_DIR}/web_server-cert.pem"
CLIENT_CERT="${CERTS_DIR}/client-cert.pem"
SERVER_CERT_PRIVATE_KEY_COPY="${CERTS_DIR}/server-cert+privatekey.pem"
CLIENT_CERT_PRIVATE_KEY_COPY="${CERTS_DIR}/client-cert+privatekey.pem"

# Extract server certificate and private key
echo "Extracting certificates and keys..."
openssl pkcs12 -in "$PFX_FILE" -out "$SERVER_CERT_PEM" -clcerts -nokeys -password pass:"$PASSWORD"
openssl pkcs12 -in "$PFX_FILE" -out "$PRIVATE_KEY_PEM" -nocerts -nodes -password pass:"$PASSWORD"

# Combine certs (conditional on second intermediate)
echo "Combining certificates..."
if [ -n "$INTERMEDIATE2_CERT" ]; then
    cat "$ROOT_CERT" "$INTERMEDIATE1_CERT" "$INTERMEDIATE2_CERT" "$SERVER_CERT_PEM" > "$COMBINED_CERT"
else
    cat "$ROOT_CERT" "$INTERMEDIATE1_CERT" "$SERVER_CERT_PEM" > "$COMBINED_CERT"
fi

# Duplicate certs for web and client
cp "$SERVER_CERT_PEM" "$WEB_SERVER_CERT"
cp "$SERVER_CERT_PEM" "$CLIENT_CERT"

cat "$SERVER_CERT_PEM" "$PRIVATE_KEY_PEM" > "$SERVER_CERT_PRIVATE_KEY_COPY"
cat "$CLIENT_CERT" "$PRIVATE_KEY_PEM" > "$CLIENT_CERT_PRIVATE_KEY_COPY"

# Generate config files

# web.conf
cat > "$CONF_DIR/web.conf" <<EOF
[settings]
enableSplunkWebSSL = true
privKeyPath = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/private-key.pem
serverCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/web_server-cert.pem
sslPassword = $server_password
EOF

# inputs.conf
cat > "$CONF_DIR/inputs.conf" <<EOF
[SSL]
serverCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/server-cert+privatekey.pem
sslPassword = $server_password
requireClientCert = false
EOF

# outputs.conf
cat > "$CONF_DIR/outputs.conf" <<EOF
[tcpout:<group_name>]
clientCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/client-cert+privatekey.pem
sslPassword = $client_password
EOF

# server.conf (no password needed)
cat > "$CONF_DIR/server.conf" <<EOF
[sslConfig]
enableSplunkdSSL = true
cliVerifyServerName = false
sslVerifyServerName = false
serverCert = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/server-cert+privatekey.pem
caCertFile = \$SPLUNK_HOME/etc/apps/Splunk_SSL_self_signed_Config/Splunk_SSL_Certs/combined-cert.pem
EOF

echo ""
echo "✅ All certificates and configuration files have been generated successfully!"
echo "📁 Output structure:"
tree "$BASE_DIR"
