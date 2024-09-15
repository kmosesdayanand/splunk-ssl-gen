# Splunk SSL Certificate Generator
This script generates self-signed SSL certificates for Splunk.

## Usage
1. Save the script as `splunk-ssl-cert-gen.sh`
2. Make the script executable: `chmod +x splunk-ssl-cert-gen.sh`
3. Run the script: `./splunk-ssl-cert-gen.sh`

## Output
The script will generate the following files:
- `rootCA.key`: Root CA private key
- `rootCA.pem`: Root CA certificate
- `server.key`: Server private key
- `server.pem`: Server certificate
- `ca_cert.pem`: CA certificate for Splunk
- `client.pem`: Client certificate for Splunk

## Notes
- This script generates self-signed certificates. For production environments, consider using a trusted Certificate Authority.
- The certificates are generated with a validity period of 3650 days.
- The script uses OpenSSL to generate the certificates.
