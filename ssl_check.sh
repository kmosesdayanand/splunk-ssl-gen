#!/bin/bash

# Function to check if a certificate file exists
check_certificate_exists() {
    local certificate_file="$1"
    if [[ ! -f "$certificate_file" ]]; then
        echo "Error: Certificate file '$certificate_file' not found!" >&2
        return 1
    fi
    return 0
}

# Function to get certificate expiration date
get_certificate_expiration() {
    local certificate_file="$1"
    if ! check_certificate_exists "$certificate_file"; then
        return 1
    fi
    openssl x509 -enddate -noout -in "$certificate_file" 2>/dev/null | cut -d= -f2
}

# Function to get certificate issuer CN
get_certificate_issuer_cn() {
    local certificate_file="$1"
    if ! check_certificate_exists "$certificate_file"; then
        return 1
    fi
    local issuer=$(openssl x509 -in "$certificate_file" -noout -issuer -nameopt RFC2253 2>/dev/null)
    echo "$issuer" | grep -oE "CN=[^,]+" | cut -d= -f2
}

# Function to get certificate subject CN
get_certificate_subject_cn() {
    local certificate_file="$1"
    if ! check_certificate_exists "$certificate_file"; then
        return 1
    fi
    local subject=$(openssl x509 -in "$certificate_file" -noout -subject -nameopt RFC2253 2>/dev/null)
    echo "$subject" | grep -oE "CN=[^,]+" | cut -d= -f2
}

# Prompt user for certificate files
read -p "Please enter the list of certificate files separated by spaces (e.g., root.pem I1.pem server-cert.pem): " -a cert_files

# Print Expiration Dates
echo
echo "Certificate Expiration Dates:"
echo "---------------------------------------------------------------"
printf "| %-25s | %-30s |\n" "Certificate File" "Expiration Date"
echo "---------------------------------------------------------------"
for cert_file in "${cert_files[@]}"; do
    expiration=$(get_certificate_expiration "$cert_file")
    if [[ -z "$expiration" ]]; then
        expiration="Invalid certificate"
    fi
    printf "| %-25s | %-30s |\n" "$cert_file" "$expiration"
done
echo "---------------------------------------------------------------"

# Print Certificate Chain Information
echo
echo "Certificate Chain Information:"
echo "------------------------------------------------------------------------------------------"
printf "| %-25s | %-30s | %-30s |\n" "Certificate File" "Issuer CN" "Subject CN"
echo "------------------------------------------------------------------------------------------"
declare -A cert_issuer
declare -A cert_subject

for cert_file in "${cert_files[@]}"; do
    issuer_cn=$(get_certificate_issuer_cn "$cert_file")
    subject_cn=$(get_certificate_subject_cn "$cert_file")

    if [[ -z "$issuer_cn" || -z "$subject_cn" ]]; then
        echo "Warning: Skipping certificate '$cert_file' due to missing CN values." >&2
        continue
    fi

    cert_issuer["$cert_file"]="$issuer_cn"
    cert_subject["$cert_file"]="$subject_cn"

    printf "| %-25s | %-30s | %-30s |\n" "$cert_file" "$issuer_cn" "$subject_cn"
done
echo "------------------------------------------------------------------------------------------"

# Attempt to determine the root certificate (where Issuer CN == Subject CN)
root_cert=""
root_cert_count=0
for cert_file in "${cert_files[@]}"; do
    if [[ "${cert_issuer[$cert_file]}" == "${cert_subject[$cert_file]}" ]]; then
        root_cert="$cert_file"
        ((root_cert_count++))
    fi
done

if [[ "$root_cert_count" -eq 1 ]]; then
    echo "Root Certificate Identified: $root_cert"
else
    if [[ "$root_cert_count" -gt 1 ]]; then
        echo "Warning: Multiple certificates with Issuer CN == Subject CN found. Please verify the certificate chain." >&2
    else
        echo "Error: Could not determine the root certificate. Ensure certificates are in a valid chain." >&2
    fi
fi
