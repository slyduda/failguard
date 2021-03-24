#!/bin/sh
source $(dirname "$0")/utils/do_patches.sh
source $(dirname "$0")/main/build_setup.sh

do_patch_root_login
do_patch_resolved

sudo apt-get update -qq -y
sudo apt-get upgrade -qq -y
sudo apt-get install jq -qq -y

# Get Generald Info
read -p "Enter VPC ID : " VPC_ID
read -p "Enter Region : " REGION
read -p "Enter SSH Key ID : " SSH_KEY_ID
read -p "Enter Bearer Token : " BEARER_TOKEN
read -p "Enter your DB Name : " DB_NAME
read -p "Enter your Cluster Name : " CLUSTER_NAME
read -p "Enter your Domain : " DOMAIN
read -p "Enter your Private Gateway IP : " GATEWAY_IP

# Host credentials
read -p "Enter a username : " USERNAME
read -s -p "Enter password : " PASSWORD
printf '\n'

# Postgres Manager Surperuser credentials
read -s -p "Create a postgres (superuser) password for your management db : " POSTGRES_MANAGER_PASSWORD
printf '\n'

# Postgres Primary Superuser credentials
read -s -p "Create a postgres (superuser) password for your primary db : " POSTGRES_PASSWORD
printf '\n'

# Postgres Replication credentials
read -s -p "Create a replication user password : " REPLICATION_PASSWORD
printf '\n'


# EMPTY VARIABLES
MANAGER_IP=''
PRIMARY_IP=''
STANDBY_IP=''
BACKUP_IP=''
BUILD_IP=''

MANAGER_NAME=''
PRIMARY_NAME=''
BACKUP_NAME=''
STANDBY_NAME=''
BUILD_NAME=''

# Generate a cipher password
CIPHER_PASSWORD=$(openssl rand -base64 48)

# Test Config Only
# VPC_ID=$( jq -r ".environment.vpc" config.prod.json ) 
# REGION=$( jq -r ".environment.region" config.prod.json )
# SSH_KEY_ID=$( jq -r ".environment.ssh_key" config.prod.json )
# BEARER_TOKEN=$( jq -r ".environment.api_key" config.prod.json )
# 
# CLUSTER_NAME=$( jq -r ".server.cluster_name" config.prod.json )
# DOMAIN=$( jq -r ".server.domain" config.prod.json )
# USERNAME=$( jq -r ".server.username" config.prod.json )
# PASSWORD=$( jq -r ".server.password" config.prod.json )
# 
# DB_NAME=$(  jq -r ".database.name" config.prod.json )
# POSTGRES_MANAGER_PASSWORD=$( jq -r ".database.password" config.prod.json )
# POSTGRES_PASSWORD=$( jq -r ".database.management_password" config.prod.json )
# REPLICATION_PASSWORD=$( jq -r ".database.replication_password" config.prod.json )

# MANAGER_IP=$( jq -r ".server.instances.management.ip" config.prod.json )
# PRIMARY_IP=$( jq -r ".server.instances.primary.ip" config.prod.json )
# STANDBY_IP=$( jq -r ".server.instances.standby[0].ip" config.prod.json )
# BACKUP_IP=$( jq -r ".server.instances.backup.ip" config.prod.json )
# BUILD_IP=$( jq -r ".server.instances.build.ip" config.prod.json )
# 
# MANAGER_NAME=$( jq -r ".server.instances.management.name" config.prod.json )
# PRIMARY_NAME=$( jq -r ".server.instances.primary.name" config.prod.json )
# BACKUP_NAME=$( jq -r ".server.instances.backup.name" config.prod.json )
# STANDBY_NAME=$( jq -r ".server.instances.standby[0].name" config.prod.json)
# BUILD_NAME=$( jq -r ".server.instances.build.name" config.prod.json )

# CIPHER_PASSWORD=$( jq -r ".database.cipher_password" config.prod.json )

echo $VPC_ID
echo $REGION
echo $SSH_KEY_ID
echo $BEARER_TOKEN

echo $CLUSTER_NAME
echo $DOMAIN
echo $USERNAME
echo $PASSWORD

echo $DB_NAME
echo $POSTGRES_MANAGER_PASSWORD
echo $POSTGRES_PASSWORD
echo $REPLICATION_PASSWORD

echo $MANAGER_IP
echo $PRIMARY_IP
echo $STANDBY_IP
echo $BACKUP_IP
echo $BUILD_IP

echo $MANAGER_NAME
echo $PRIMARY_NAME
echo $BACKUP_NAME
echo $STANDBY_NAME
echo $BUILD_NAME

echo $GATEWAY_IP

echo $CIPHER_PASSWORD


# Initial Build
init_build()
{
    build_droplets
    build_pgbackrest
    
    # Install pgbackrest on each machine
    install_pgbackrest $PRIMARY_IP
    install_pgbackrest $STANDBY_IP
    install_pgbackrest $BACKUP_IP
}

init_manager()
{
    echo "Manager Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} \
        "USERNAME=$USERNAME; PASSWORD=$PASSWORD; GATEWAY_IP=$GATEWAY_IP; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; POSTGRES_PASSWORD=$POSTGRES_MANAGER_PASSWORD; $(<utils/db_setup.sh); $(<utils/initial_setup.sh); $(<utils/private_setup.sh); $(<utils/do_patches.sh); $(<main/initial_setup.sh); $(<main/failguard_utils.sh); $(<main/manager_tooling.sh); $(<manager_setup.sh);"
    echo "Manager Setup Complete"
}

init_primary()
{
    echo "Primary Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} \
        "USERNAME=$USERNAME; PASSWORD=$PASSWORD; DB_NAME=$DB_NAME; POSTGRES_PASSWORD=$POSTGRES_PASSWORD; GATEWAY_IP=$GATEWAY_IP; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(<utils/db_setup.sh); $(<utils/initial_setup.sh); $(<utils/private_setup.sh); $(<utils/do_patches.sh); $(<main/build_setup.sh);  $(<main/initial_setup.sh); $(<main/failguard_utils.sh); $(<main/primary_tooling.sh); $(<primary_setup.sh);"
    echo "Primary Setup Complete"
}

init_backup()
{
    echo "Backup Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} \
        "USERNAME=$USERNAME; PASSWORD=$PASSWORD; GATEWAY_IP=$GATEWAY_IP; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(<utils/db_setup.sh); $(<utils/initial_setup.sh); $(<utils/private_setup.sh); $(<utils/do_patches.sh); $(<main/build_setup.sh); $(<main/initial_setup.sh); $(<main/failguard_utils.sh); $(<main/backup_tooling.sh); $(<backup_setup.sh);"
    echo "Backup Setup Complete"
}

init_standby()
{
    echo "Standby Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${STANDBY_IP} \
        "USERNAME=$USERNAME; PASSWORD=$PASSWORD; DB_NAME=$DB_NAME; POSTGRES_PASSWORD=$POSTGRES_PASSWORD; GATEWAY_IP=$GATEWAY_IP; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; CLUSTER_NAME=$CLUSTER_NAME; REPLICATION_PASSWORD=$REPLICATION_PASSWORD; $(<utils/db_setup.sh); $(<utils/initial_setup.sh); $(<utils/private_setup.sh); $(<utils/do_patches.sh); $(<main/build_setup.sh); $(<main/initial_setup.sh); $(<main/failguard_utils.sh); $(<main/standby_tooling.sh); $(<standby_setup.sh);"
    echo "Standby Setup Complete"
}

setup_backup()
{
    echo "Backup Second Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} \
        "PRIMARY_NAME=$PRIMARY_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(<main/failguard_utils.sh); $(<main/backup_tooling.sh); $(<backup_final.sh);"
    echo "Backup Second Setup Complete"
}

setup_primary()
{
    echo "Primary Second Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} \
        "BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; CIPHER_PASSWORD=$CIPHER_PASSWORD; CLUSTER_NAME=$CLUSTER_NAME; STANDBY_IP=$STANDBY_IP; REPLICATION_PASSWORD=$REPLICATION_PASSWORD; $(<main/failguard_utils.sh); $(<main/primary_tooling.sh); $(<primary_final.sh);"
    echo "Primary Second Setup Complete"
}

start_standby()
{
    echo "Starting Standby"
    ssh -q -A -o "StrictHostKeyChecking no" root@${STANDBY_IP} \
        "CLUSTER_NAME=$CLUSTER_NAME; $(<main/failguard_utils.sh); $(<standby_start.sh);"
    echo "Standby completed"
}

start_backup()
{
    echo "Starting Backup"
    ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} \
        "CLUSTER_NAME=$CLUSTER_NAME; $(<main/failguard_utils.sh); $(<backup_start.sh);"
    echo "Backup completed"
}

finish_manager()
{
    echo "Finalizing Manager"
    ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} \
        "CLUSTER_NAME=$CLUSTER_NAME; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; $(<main/failguard_utils.sh); $(<main/manager_tooling.sh); $(<manager_final.sh);"
    echo "Manager completed"
}

init_build
init_manager
init_primary
init_backup
init_standby
setup_backup
setup_primary
# start_standby
# start_backup
finish_manager
self_destruct