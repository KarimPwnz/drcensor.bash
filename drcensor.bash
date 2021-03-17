#!/bin/bash
# ./drcensor.bash DOMAIN OPTIONAL_TIMEOUT
# by Karim Rahal

# Colors
readonly RED=$(tput setaf 1)
readonly MAGENTA=$(tput setaf 5)
readonly RESET=$(tput sgr 0)

print_step() {
    printf "\n${MAGENTA}=====\n"
    printf "$1"
    printf "\n=====\n\n$RESET"
}

print_error() {
    printf "\n${RED}$1\n\b$RESET"
}

# Argument parsing
domain="$1"

if [[ $# -lt 1 ]]; then
    print_error "Provide a domain to test!"
    exit 1
fi

if [[ $# -eq 2 ]]; then
    timeout="$2"
else
    timeout="15"
fi

# Print AS info
print_step "Getting AS info"
ip="$(curl -s https://api.ipify.org/?format=txt)"
[[ $? -ne 0 ]] && print_error "Cannot send HTTPS request to get IP" && exit 1
whois -h v4.whois.cymru.com " -v $ip"

# Check with system resolver
print_step "Checking DNS with system's resolver"
if dig "example.com" &>/dev/null; then
    echo "dig $domain"
    dig $domain
    [[ $? -ne 0 ]] && print_error "DNS resolution failed"
else
    print_error "System's DNS resolver dead?"
fi

# Check with cloudflare DNS
print_step "Checking DNS with Cloudflare's resolver (1.1.1.1)"
if dig @1.1.1.1 "example.com" &>/dev/null; then
    echo "dig @1.1.1.1 $domain"
    dig @1.1.1.1 $domain
    [[ $? -ne 0 ]] && print_error "DNS resolution with Cloudflare failed"
else
    print_error "Cloudflare's DNS resolver dead/blocked?"
fi

# Do DoH resolution (using regex because jq may not be available)
cloudflare_DNS="$(curl -s -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$domain&type=A")"
[[ "$cloudflare_DNS" =~ \"data\":\"([0-9\.]+)\" ]]
cloudflare_DNS="${BASH_REMATCH[1]}"

# Check if Cloudflare DoH record is not set or null (needed for next steps)
if [[ -n $cloudflare_DNS ]]; then
    # Check HTTP blocking
    print_step "Checking HTTP (with Cloudflare's DoH)"
    echo "curl -s -v -m $timeout --resolve $domain:80:$cloudflare_DNS http://$domain"
    curl -s -v -m $timeout --resolve "$domain:80:$cloudflare_DNS" "http://$domain"
    [[ $? -ne 0 ]] && print_error "HTTP request failed"

    # Check HTTPS blocking
    print_step "Checking HTTPS (with Cloudflare's DoH)"
    echo "curl -s -v -m $timeout --resolve $domain:443:$cloudflare_DNS https://$domain"
    curl -s -v -m $timeout --resolve "$domain:443:$cloudflare_DNS" "https://$domain"
    [[ $? -ne 0 ]] && print_error "HTTPS request failed"
else
    print_error "https://cloudflare-dns.com is dead/blocked?"
fi