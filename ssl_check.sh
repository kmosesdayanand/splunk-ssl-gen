#!/bin/bash

# Usage: ./test1.sh [ascending|descending] root.pem intermediate.pem ... server-cert.pem

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 [ascending|descending] root.pem intermediate.pem ... server-cert.pem"
    exit 1
fi

direction=$1
shift

if [[ "$direction" != "ascending" && "$direction" != "descending" ]]; then
    echo "Error: First argument must be 'ascending' or 'descending'"
    exit 1
fi

declare -A subject_map
declare -A issuer_map
declare -A expiry_map
declare -A file_map
declare -A cn_map

cert_files=("$@")

# Check if all files exist
for file in "${cert_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found!"
        exit 1
    fi
done

# Extract information
for cert in "${cert_files[@]}"; do
    subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/^subject=//')
    issuer=$(openssl x509 -in "$cert" -noout -issuer 2>/dev/null | sed 's/^issuer=//')
    not_after=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d= -f2)

    cn=$(echo "$subject" | sed -n 's/.*CN[ =]\(.*\)/\1/p')
    if [[ -z "$cn" ]]; then
        cn="(CN Not Found)"
    fi

    subject_key=$(echo -n "$subject" | openssl dgst -sha256 | awk '{print $2}')
    issuer_key=$(echo -n "$issuer" | openssl dgst -sha256 | awk '{print $2}')

    subject_map["$subject_key"]="$issuer_key"
    issuer_map["$subject_key"]="$issuer"
    expiry_map["$subject_key"]="$not_after"
    file_map["$subject_key"]="$cert"
    cn_map["$subject_key"]="$cn"
done

# Find the root cert (self-signed)
root_key=""
for subject_key in "${!subject_map[@]}"; do
    if [[ "${subject_map[$subject_key]}" == "$subject_key" ]]; then
        root_key="$subject_key"
        break
    fi
done

if [[ -z "$root_key" ]]; then
    echo "Error: Could not determine root certificate (self-signed cert not found)."
    exit 1
fi

# Build chain from root to leaf
chain=()
visited=()
current_key="$root_key"
while [[ -n "$current_key" ]]; do
    chain+=("$current_key")
    visited+=("$current_key")

    next_key=""
    for skey in "${!subject_map[@]}"; do
        if [[ "${subject_map[$skey]}" == "$current_key" && ! " ${visited[*]} " =~ " $skey " ]]; then
            next_key="$skey"
            break
        fi
    done
    current_key="$next_key"
done

# Reverse for descending (leaf to root)
if [[ "$direction" == "descending" ]]; then
    reversed_chain=()
    for (( i=${#chain[@]}-1; i>=0; i-- )); do
        reversed_chain+=("${chain[$i]}")
    done
    chain=("${reversed_chain[@]}")
fi

# Print result as a clean table
printf "\n%-30s | %-50s | %-25s\n" "Filename" "Common Name (CN)" "Expiration Date"
printf "%s\n" "---------------------------------------------------------------------------------------------------------------"
for key in "${chain[@]}"; do
    cert_file="${file_map[$key]}"
    cn="${cn_map[$key]}"
    expiry="${expiry_map[$key]}"
    printf "%-30s | %-50s | %-25s\n" "$cert_file" "$cn" "$expiry"
done
echo ""
