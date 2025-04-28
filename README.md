# splunk-ssl-gen

> **Automate SSL Certificate Generation & Configuration for Splunk**  
> _Because life’s too short to manage SSL by hand._

---

## 🚀 Overview

**splunk-ssl-gen** is a collection of scripts that streamline the creation, management, and configuration of SSL certificates for Splunk environments.  
Whether you need **self-signed certificates**, **third-party CA certificates**, or need to **convert PFX bundles** into Splunk-friendly formats — these scripts have you covered.

Spend less time wrestling with OpenSSL commands and more time securing your data!

---

## 📜 Scripts Included

| Script | Purpose |
|:------|:--------|
| `self-signed_ssl_gen_&_Splunk_config.sh` | Generate self-signed SSL certificates and Prepare configuration for Splunk automatically. |
| `ssl_pfx_gen.sh` | Create a PFX (PKCS#12) file bundling your private key and certs. |
| `pfx_ssl_to_Splunk_config.sh` | Extract and Prepare config for Splunk from an existing PFX file. |
| `third-party_ssl_certs_&_Splunk_Config.sh` | Use SSL certificates signed by trusted Certificate Authorities to prepare Splunk Configration |
| `ssl_check.sh` | Validate SSL certificate deployments and check for common issues. |

---

## 🛠️ Usage



### 1. Make scripts executable:
```bash
chmod +x <scriptname.sh>
```

### 2. ssl_check.sh:
```bash
./ssl_check.sh
```
For example:
```
Please enter the list of certificate files separated by spaces (e.g., root.pem I1.pem server-cert.pem): root.pem server.pem intermediate.pem
```

