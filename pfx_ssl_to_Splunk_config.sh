#!/bin/bash

# Ask for PFX file path and password
echo "Please enter the path to your PFX file (e.g., server.pfx):"
read PFX_FILE

echo "Please enter the password for the PFX file:"
read -s PASSWORD  # Using -s to hide the password input

# Set output directory and certificate file paths
OUTPUT_DIR="./output"
SERVER_CERT_PEM="${OUTPUT_DIR}/server-cert.pem"
PRIVATE_KEY_PEM="${OUTPUT_DIR}/private-key.pem"

# Ask for intermediate and root certificate paths
echo "Please enter the path to your intermediate certificate (e.g., intermediate-cert.pem):"
read INTERMEDIATE_CERT

echo "Please enter the path to your root certificate (e.g., root-cert.pem):"
read ROOT_CERT

# Combined certificate path
COMBINED_CERT="${OUTPUT_DIR}/combined-cert.pem"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Step 1: Extract server certificate and private key from the PFX file
echo "Extracting server certificate and private key from pfx file..."
openssl pkcs12 -in "$PFX_FILE" -out "$SERVER_CERT_PEM" -clcerts -nokeys -password pass:"$PASSWORD"
openssl pkcs12 -in "$PFX_FILE" -out "$PRIVATE_KEY_PEM" -nocerts -nodes -password pass:"$PASSWORD"

# Step 2: Combine the certificates: root, intermediate, and server in the correct order (root, intermediate, server)
echo "Combining root, intermediate, and server certificates into one..."
cat "$ROOT_CERT" "$INTERMEDIATE_CERT" "$SERVER_CERT_PEM" > "$COMBINED_CERT"

# Step 3: Duplicate server cert for web server and client cert
echo "Creating duplicate certificates..."

# Web server certificate
WEB_SERVER_CERT="${OUTPUT_DIR}/web_server-cert.pem"
cp "$SERVER_CERT_PEM" "$WEB_SERVER_CERT"
echo "Web server certificate created at: $WEB_SERVER_CERT"

# Client certificate
CLIENT_CERT="${OUTPUT_DIR}/client-cert.pem"
cp "$SERVER_CERT_PEM" "$CLIENT_CERT"
echo "Client certificate created at: $CLIENT_CERT"

# Copy of server certificate with private key
SERVER_CERT_PRIVATE_KEY_COPY="${OUTPUT_DIR}/server-cert+privatekey.pem"
cat "$SERVER_CERT_PEM" "$PRIVATE_KEY_PEM" > "$SERVER_CERT_PRIVATE_KEY_COPY"
echo "Server certificate with private key copy created at: $SERVER_CERT_PRIVATE_KEY_COPY"

# Copy of client certificate with private key
CLIENT_CERT_PRIVATE_KEY_COPY="${OUTPUT_DIR}/client-cert+privatekey.pem"
cat "$CLIENT_CERT" "$PRIVATE_KEY_PEM" > "$CLIENT_CERT_PRIVATE_KEY_COPY"
echo "Client certificate with private key copy created at: $CLIENT_CERT_PRIVATE_KEY_COPY"

# Final output listing in the requested order
echo "Process completed. The following certificates and keys have been generated:"
echo "1. Server certificate: $SERVER_CERT_PEM"
echo "2. Client certificate: $CLIENT_CERT"
echo "3. Server certificate with private key copy: $SERVER_CERT_PRIVATE_KEY_COPY"
echo "4. Client certificate with private key copy: $CLIENT_CERT_PRIVATE_KEY_COPY"
echo "5. Combined certificate: $COMBINED_CERT"
echo "6. Web server certificate: $WEB_SERVER_CERT"
