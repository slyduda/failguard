#!/bin/sh
source $(dirname "$0")/db_setup.sh
source $(dirname "$0")/build_setup.sh
source $(dirname "$0")/initial_setup.sh
source $(dirname "$0")/private_setup.sh
source $(dirname "$0")/failguard_backup/utils.sh
source $(dirname "$0")/failguard_backup/backup_setup.sh
source $(dirname "$0")/failguard_backup/initial_setup.sh
source $(dirname "$0")/failguard_backup/primary_setup.sh
source $(dirname "$0")/failguard_backup/standby_setup.sh
source $(dirname "$0")/failguard_backup/manager_setup.sh

# Get Generald Info
read -p "Enter VPC ID : " VPC_ID
read -p "Enter Region : " REGION
read -p "Enter SSH Key ID : " KEY_ID
read -p "Enter Bearer Token : " BEARER_TOKEN
read -p "Enter your DB Name : " DB_NAME
read -p "Enter your Cluster Name : " CLUSTER_NAME
read -p "Enter your Domain : " DOMAIN

# Host credentials
read -p "Enter a username : " USERNAME
read -s -p "Enter password : " PASSWORD
printf '\n'

# Postgres Superuser credentials
read -s -p "Create a postgres (superuser) password : " POSTGRES_PASSWORD
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

build_setup()
{
    build_droplets
    build_pgbackrest
}

manager_setup()
{
    # SSH to Manager Server
    configure_server $USERNAME $PASSWORD
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME
    
    # Exit
}

primary_setup()
{
    # SSH to Primary Server
    
    # Initial Config
    configure_private_droplet
    configure_server $USERNAME $PASSWORD
    
    # Create Hosts and Keys
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
    create_ssh_keys postgres
    
    # Install postgres and pgbackrest
    install_postgres $DB_NAME $POSTGRES_PASSWORD
    install_pgbackrest $BUILD_IP

    # Create pgbackrest config
    create_pgbackrest_config postgres
    create_pgbackrest_repository postgres
    set_archiving_primary_config $CLUSTER_NAME


    # create_pgbackrest_repository postgres # Only for local repository
    # restart_cluster $CLUSTER_NAME
    
    # Exit
}

backup_setup() 
{
    # SSH to Backup Server

    # Initial Config
    configure_private_droplet
    configure_server $USERNAME $PASSWORD
    
    # Create Hosts and Keys
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
    create_ssh_keys postgres

    # Install pgbackrest
    install_pgbackrest $BUILD_IP

    # Create pgbackrest config
    create_pgbackrest_config pgbackrest
    create_pgbackrest_repository pgbackrest
    set_backup_config $PRIMARY_NAME $CLUSTER_NAME
    
    # Share Backup Key with Primary 
    send_pgbackrest_public_key $STANDBY_NAME
    
    # restart_cluster $CLUSTER_NAME

    # Exit
}

standby_setup() 
{
    # SSH to Standby Server

    # Initial Config
    configure_private_droplet
    configure_server $USERNAME $PASSWORD

    # Create Hosts and Keys
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME
    create_ssh_keys postgres

    # Install postgres and pgbackrest
    install_postgres $DB_NAME $POSTGRES_PASSWORD
    install_pgbackrest $BUILD_IP

    # Create pgbackrest config
    create_pgbackrest_config postgres
    create_pgbackrest_repository postgres
    set_streaming_standby_config $PRIMARY_NAME $BACKUP_NAME $REPLICATION_PASSWORD $CLUSTER_NAME
    
    # Share Standby Key with Backup 
    send_postgres_public_key $BACKUP_NAME
    
    # Exit
}


finish_backup_setup()
{
    # SSH to Standby Server

    # Share Backup Key with Standby 
    send_pgbackrest_public_key $STANDBY_NAME

    # Configure the Backup Server for Standby Backup 
    set_backup_standby_backup_config $PRIMARY_NAME $STANDBY_IP $CLUSTER_NAME
    # Exit
}

finish_primary_setup()
{
    # SSH to Primary Server

    # Share Primary Key with Backup
    send_postgres_public_key $BACKUP_NAME
    
    # Configure the Primary Server for Streaming and Standby Backup 
    set_backup_standby_primary_config $BACKUP_NAME  $CIPHER_PASSWORD $CLUSTER_NAME 
    set_replica_streaming_primary_config  $STANDBY_IP $REPLICATION_PASSWORD $CLUSTER_NAME
    # Exit
}

start_standby()
{
    start_cluster $CLUSTER_NAME
}

start_backup()
{
    backup_cluster $CLUSTER_NAME
}

build_setup
# manager_setup
# primary_setup
# backup_setup
# primary_auth
# standby_setup
# finish_backup_setup
# finish_primary_setup