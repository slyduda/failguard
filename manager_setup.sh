#!/bin/sh
# -------------------------- #
# ------ Manager Setup ----- #
# -------------------------- #

read -p "Enter SSH Key ID : " KEY_ID
read -p "Enter Bearer Token : " BEARER_TOKEN
read -p "Enter VPC ID : " VPC_ID
read -p "Enter region (Match VPC) : " REGION
read -p "Enter your db identifying name : " DB_NAME
# read -p "Enter host prefix : " subdomain
read -p "Enter domain : " DOMAIN

# Create a random uuid for the standby.
uuidSample=$(uuidgen)
IFS='-'
read -a strarr <<< "$uuidSample"
UNIQUEID=${strarr[0]}

# Later we can do it without regions
MANAGER_HOSTNAME="db-manager.${REGION}.$DOMAIN" 
BACKUP_HOSTNAME="db-backup.${REGION}.${DOMAIN}"
PRIMARY_HOSTNAME="${DB_NAME}-db.${REGION}.${DOMAIN}"
STANDBY_HOSTNAME="${DB_NAME}-db-${UNIQUEID}.${REGION}.${DOMAIN}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -d '{"names":"[${MANAGER_HOSTNAME}, ${BACKUP_HOSTNAME}, ${PRIMARY_HOSTNAME}, ${STANDBY_HOSTNAME}]","region":"${REGION}","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":[${KEY_ID}],"backups":false,"ipv6":true,"vpc_uuid":"${VPC_ID}"}' \
    "https://api.digitalocean.com/v2/droplets" | jq '(.droplets | .[] | .name, .id)'

# Store ids and names in postgres database
# Example data from curl

#"sub-01.example.com"
#3164494
#"sub-02.example.com"
#3164495

# Get the private IP addresses of each

# SSH into Manager 
# PRIVATE_IP_MANAGER=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
# Exit

# SSH into Backup 
# PRIVATE_IP_BACKUP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
# Exit

# SSH into Primary 
# PRIVATE_IP_PRIMARY=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
# Exit

# SSH into Standby 
# PRIVATE_IP_STANDBY=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
# Exit