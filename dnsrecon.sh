#!/bin/bash

# --- Configuration ---
# Default output directory
OUTPUT_DIR="dnsrecon_results"
# Default wordlist for brute-force (adjust if yours is different)
WORDLIST="/usr/share/wordlists/dnsrecon/namelist.txt"

# --- Argument Handling ---
# Check if a filename was provided as the first argument
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_domains_file>"
    echo "Example: $0 my_targets.txt"
    exit 1 # Exit with an error code
fi

DOMAINS_FILE="$1" # Assign the first argument to DOMAINS_FILE

# Check if the provided domains file exists
if [ ! -f "$DOMAINS_FILE" ]; then
    echo "Error: Domains file '$DOMAINS_FILE' not found."
    exit 1
fi

# --- Script Logic ---
echo "[+] Starting DNS Reconnaissance from: $DOMAINS_FILE"
mkdir -p "$OUTPUT_DIR" # Create the output directory if it doesn't exist

# Check if the wordlist exists (important for brute-force)
if [ ! -f "$WORDLIST" ]; then
    echo "Warning: Wordlist '$WORDLIST' not found. Brute-force enumeration (-t brt) will fail."
    echo "Please update the WORDLIST variable in the script or ensure the file exists."
    # You might choose to exit here, or continue without brute-force.
    # For now, we'll just warn.
fi

while IFS= read -r domain; do
    # Trim whitespace and skip empty lines
    domain=$(echo "$domain" | xargs)
    if [[ -z "$domain" ]]; then
        continue # Skip empty lines
    fi

    echo "------------------------------------"
    echo "[*] Running dnsrecon on: $domain"

    # Define common dnsrecon options
    DNSRECON_OPTIONS="-d \"$domain\" -t std,axfr,brt --json \"$OUTPUT_DIR/${domain}.json\""

    # Add the wordlist option only if the brute-force type is selected AND wordlist exists
    if [[ "$DNSRECON_OPTIONS" == *"-t "*brt* ]]; then
        if [ -f "$WORDLIST" ]; then
            DNSRECON_OPTIONS="$DNSRECON_OPTIONS -D \"$WORDLIST\""
        else
            echo "    [!] Skipping brute-force for $domain as wordlist not found."
            # Remove -t brt if wordlist is missing to avoid dnsrecon error
            DNSRECON_OPTIONS=$(echo "$DNSRECON_OPTIONS" | sed 's/,brt//; s/brt,//; s/brt//')
        fi
    fi

    # Execute dnsrecon command
    eval dnsrecon $DNSRECON_OPTIONS

    echo "[*] Finished dnsrecon on: $domain"

done < "$DOMAINS_FILE"

echo "------------------------------------"
echo "[+] DNS Reconnaissance complete for all domains. Results in '$OUTPUT_DIR/'"
