#!/bin/bash

# Ask for PFX file path and password
echo "Please enter the path to your PFX file (e.g., server.pfx):"
read PFX_FILE

echo "Please enter the password for the PFX file (this will also be used as sslPassword):"
read -s PASSWORD  # Using -s to hide the password input

# Ask for certificate chain components
echo "Enter the path to your root certificate (e.g., root-cert.pem):"
read ROOT_CERT

echo "Enter the path to your Level 1 intermediate certificate (e.g., intermediate1-cert.pem):"
read INTERMEDIATE1_CERT

echo "Enter the path to your Level 2 intermediate certificate (e.g., intermediate2-cert.pem):"
read INTERMEDIATE2_CERT

# Use PFX password as both server and client key passwords
server_password="$PASSWORD"
client_password="$PASSWORD"

# Set output directories
BASE_DIR="./pfx_ssl_to_Splunk_config"
CERT_DIR="${BASE_DIR}/certs"
CONF_DIR="${BASE_DIR}/local"

# Create directories
mkdir -p "$CERT_DIR"
mkdir -p "$CONF_DIR"

# Define certificate file paths
SERVER_CERT_PEM="${CERT_DIR}/server-cert.pem"
PRIVATE_KEY_PEM="${CERT_DIR}/private-key.pem"
COMBINED_CERT="${CERT_DIR}/combined-cert.pem"
WEB_SERVER_CERT="${CERT_DIR}/web_server-cert.pem"
CLIENT_CERT="${CERT_DIR}/client-cert.pem"
SERVER_CERT_PRIVATE_KEY_COPY="${CERT_DIR}/server-cert+privatekey.pem"
CLIENT_CERT_PRIVATE_KEY_COPY="${CERT_DIR}/client-cert+privatekey.pem"

# Step 1: Extract server certificate and private key from the PFX file
echo "Extracting server certificate and private key from PFX..."
openssl pkcs12 -in "$PFX_FILE" -out "$SERVER_CERT_PEM" -clcerts -nokeys -password pass:"$PASSWORD"
openssl pkcs12 -in "$PFX_FILE" -out "$PRIVATE_KEY_PEM" -nocerts -nodes -password pass:"$PASSWORD"

# Step 2: Combine the full certificate chain + server cert
echo "Combining root, intermediate1, intermediate2, and server certificates..."
cat "$ROOT_CERT" "$INTERMEDIATE1_CERT" "$INTERMEDIATE2_CERT" "$SERVER_CERT_PEM" > "$COMBINED_CERT"

# Step 3: Duplicate certs for different roles
echo "Creating duplicate certs..."
cp "$SERVER_CERT_PEM" "$WEB_SERVER_CERT"
cp "$SERVER_CERT_PEM" "$CLIENT_CERT"

cat "$SERVER_CERT_PEM" "$PRIVATE_KEY_PEM" > "$SERVER_CERT_PRIVATE_KEY_COPY"
cat "$CLIENT_CERT" "$PRIVATE_KEY_PEM" > "$CLIENT_CERT_PRIVATE_KEY_COPY"

# Step 4: Generate Splunk config files
echo "Generating Splunk .conf files..."

cat > "$CONF_DIR/web.conf" <<EOF
[settings]
enableSplunkWebSSL = true
privKeyPath = \$SPLUNK_HOME/etc/apps/pfx_ssl_to_Splunk_config/certs/private-key.pem
serverCert = \$SPLUNK_HOME/etc/apps/pfx_ssl_to_Splunk_config/certs/web_server-cert.pem
sslPassword = $server_password
EOF

cat > "$CONF_DIR/server.conf" <<EOF
[sslConfig]
enableSplunkdSSL = true
cliVerifyServerName = false
sslVerifyServerName = false
serverCert = \$SPLUNK_HOME/etc/apps/pfx_ssl_to_Splunk_config/certs/server-cert+privatekey.pem
caCertFile = \$SPLUNK_HOME/etc/apps/pfx_ssl_to_Splunk_config/certs/combined-cert.pem
EOF

cat > "$CONF_DIR/outputs.conf" <<EOF
[tcpout:<group_name>]
clientCert = \$SPLUNK_HOME/etc/apps/pfx_ssl_to_Splunk_config/certs/client-cert+privatekey.pem
sslPassword = $client_password
EOF

cat > "$CONF_DIR/inputs.conf" <<EOF
[SSL]
serverCert = \$SPLUNK_HOME/etc/apps/pfx_ssl_to_Splunk_config/certs/server-cert+privatekey.pem
sslPassword = $server_password
requireClientCert = false
EOF

# Done!
echo -e "\n✅ Done! Your Splunk TLS certs and configs are ready in: $BASE_DIR"

# Tree preview (optional)
echo -e "\nDirectory structure:"
tree "$BASE_DIR"
