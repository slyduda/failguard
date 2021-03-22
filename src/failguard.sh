#!/bin/sh

source $(dirname "$0")/util/db_setup.sh
source $(dirname "$0")/util/initial_setup.sh
source $(dirname "$0")/util/private_setup.sh

source $(dirname "$0")/main/utils.sh
source $(dirname "$0")/main/build_setup.sh
source $(dirname "$0")/main/initial_setup.sh
source $(dirname "$0")/main/backup_tooling.sh
source $(dirname "$0")/main/primary_tooling.sh
source $(dirname "$0")/main/standby_tooling.sh
source $(dirname "$0")/main/manager_tooling.sh

# Get Generald Info
read -p "Enter VPC ID : " VPC_ID
read -p "Enter Region : " REGION
read -p "Enter SSH Key ID : " SSH_KEY_ID
read -p "Enter Bearer Token : " BEARER_TOKEN
read -p "Enter your DB Name : " DB_NAME
read -p "Enter your Cluster Name : " CLUSTER_NAME
read -p "Enter your Domain : " DOMAIN

# Host credentials
read -p "Enter a username : " USERNAME
read -s -p "Enter password : " PASSWORD
printf '\n'

# Postgres Manager Surperuser credentials
read -s -p "Create a postgres (superuser) password for your management db : " POSTGRES_MANAGER_PASSWORD

# Postgres Primary Superuser credentials
read -s -p "Create a postgres (superuser) password for your primary db : " POSTGRES_PASSWORD
printf '\n'

# Postgres Replication credentials
read -s -p "Create a replication user password : " REPLICATION_PASSWORD
printf '\n'

# Generate a cipher password
CIPHER_PASSWORD=$(openssl rand -base64 48)

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

# Initial Build
build_droplets
build_pgbackrest


# Begin Threading through servers
echo "Manager Setup Started"
ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} \
    "USERNAME=$USERNAME; PASSWORD=$PASSWORD; POSTGRES_PASSWORD=$POSTGRES_MANAGER_PASSWORD; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(< $(dirname "$0")/util/db_setup.sh); $(< $(dirname "$0")/util/initial_setup.sh); $(< $(dirname "$0")/util/private_setup.sh); $(< $(dirname "$0")/main/manager_tooling.sh); $(< $(dirname "$0")/manager_setup.sh);"
echo "Manager Setup Complete"


echo "Primary Setup Started"
ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} \
    "USERNAME=$USERNAME; PASSWORD=$PASSWORD; DB_NAME=$DB_NAME; POSTGRES_PASSWORD=$POSTGRES_PASSWORD; BUILD_IP=$BUILD_IP; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(< $(dirname "$0")/util/db_setup.sh); $(< $(dirname "$0")/util/initial_setup.sh); $(< $(dirname "$0")/util/private_setup.sh); $(< $(dirname "$0")/main/build_setup.sh); $(< $(dirname "$0")/main/primary_tooling.sh); $(< $(dirname "$0")/primary_setup.sh);"
echo "Primary Setup Complete"


echo "Backup Setup Started"
ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} \
    "USERNAME=$USERNAME; PASSWORD=$PASSWORD; BUILD_IP=$BUILD_IP; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(< $(dirname "$0")/util/db_setup.sh); $(< $(dirname "$0")/util/initial_setup.sh); $(< $(dirname "$0")/util/private_setup.sh); $(< $(dirname "$0")/main/build_setup.sh); $(< $(dirname "$0")/main/backup_tooling.sh); $(< $(dirname "$0")/backup_setup.sh);"
echo "Backup Setup Complete"


echo "Standby Setup Started"
ssh -q -A -o "StrictHostKeyChecking no" root@${STANDBY_IP} \
    "USERNAME=$USERNAME; PASSWORD=$PASSWORD; DB_NAME=$DB_NAME; POSTGRES_PASSWORD=$POSTGRES_PASSWORD; BUILD_IP=$BUILD_IP; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; CLUSTER_NAME=$CLUSTER_NAME; REPLICATION_PASSWORD=$REPLICATION_PASSWORD; $(< $(dirname "$0")/util/db_setup.sh); $(< $(dirname "$0")/util/initial_setup.sh); $(< $(dirname "$0")/util/private_setup.sh); $(< $(dirname "$0")/main/build_setup.sh); $(< $(dirname "$0")/main/standby_tooling.sh); $(< $(dirname "$0")/standby_setup.sh);"
echo "Standby Setup Complete"


echo "Backup Finalization Started"
ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} \
    "PRIMARY_NAME=$PRIMARY_NAME; STANDBY_NAME=$STANDBY_NAME; CLUSTER_NAME=$CLUSTER_NAME; $(< $(dirname "$0")/main/failguard_utils.sh); $(< $(dirname "$0")/main/backup_tooling.sh); $(< $(dirname "$0")/backup_final.sh);"
echo "Backup Finalization Complete"


echo "Primary Finalization Started"
ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} \
    "BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; CLUSTER_NAME=$CLUSTER_NAME; CIPHER_PASSWORD=$CIPHER_PASSWORD; REPLICATION_PASSWORD=$REPLICATION_PASSWORD;  $(< $(dirname "$0")/main/failguard_utils.sh); $(< $(dirname "$0")/main/primary_tooling.sh); $(< $(dirname "$0")/primary_final.sh);"
echo "Primary Finalization Complete"


echo "Starting Standby"
ssh -q -A -o "StrictHostKeyChecking no" root@${STANDBY_IP} \
    "CLUSTER_NAME=$CLUSTER_NAME; $(< $(dirname "$0")/main/failguard_utils.sh); $(< $(dirname "$0")/standby_start.sh);"


echo "Starting Backup"
ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} \
    "CLUSTER_NAME=$CLUSTER_NAME; $(< $(dirname "$0")/main/failguard_utils.sh); $(< $(dirname "$0")/backup_start.sh);"
echo "Backup completed"

echo "Finalizing Manager"
ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} \
    "CLUSTER_NAME=$CLUSTER_NAME; PRIMARY_IP=$PRIMARY_IP; PRIMARY_NAME=$PRIMARY_NAME; BACKUP_IP=$BACKUP_IP; BACKUP_NAME=$BACKUP_NAME; STANDBY_IP=$STANDBY_IP; STANDBY_NAME=$STANDBY_NAME; MANAGER_IP=$MANAGER_IP; MANAGER_NAME=$MANAGER_NAME; $(< $(dirname "$0")/main/failguard_utils.sh); $(dirname "$0")/main/manager_tooling.sh; $(< $(dirname "$0")/manager_final.sh);"
echo "Manager completed"

echo "$CLUSTER_NAME has been created!"