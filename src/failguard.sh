#!/bin/sh
. $(dirname "$0")/utils/do_patches.sh
. $(dirname "$0")/main/build_setup.sh

do_patch_root_login
do_patch_resolved

sudo apt-get update -qq -y
sudo apt-get upgrade -qq -y
sudo apt-get install jq -qq -y

# EMPTY VARIABLES
VPC_ID=''
REGION=''
SSH_KEY_ID=''
BEARER_TOKEN=''

DB_NAME=''
SERVER_NAME=''
CLUSTER_NAME=''
DOMAIN=''
GATEWAY_IP=''
USERNAME=''
NEW_PASSWORD=''

POSTGRES_MANAGER_PASSWORD=''
POSTGRES_PASSWORD=''
REPLICATION_PASSWORD=''
CIPHER_PASSWORD=''

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

FAILGUARD_DEBUG=''

if [ -f $(dirname "$0")/config.prod.json ]; then
    VPC_ID=$( jq -r ".environment.vpc" $(dirname "$0")/config.prod.json ) 
    REGION=$( jq -r ".environment.region" $(dirname "$0")/config.prod.json )
    SSH_KEY_ID=$( jq -r ".environment.ssh_key" $(dirname "$0")/config.prod.json )
    BEARER_TOKEN=$( jq -r ".environment.api_key" $(dirname "$0")/config.prod.json )

    SERVER_NAME=$(  jq -r ".server.name" $(dirname "$0")/config.prod.json )
    DOMAIN=$( jq -r ".server.domain" $(dirname "$0")/config.prod.json )
    USERNAME=$( jq -r ".server.username" $(dirname "$0")/config.prod.json )
    NEW_PASSWORD=$( jq -r ".server.password" $(dirname "$0")/config.prod.json )

    DB_NAME=$(  jq -r ".database.name" $(dirname "$0")/config.prod.json )
    CLUSTER_NAME=$( jq -r ".database.cluster_name" $(dirname "$0")/config.prod.json )
    POSTGRES_MANAGER_PASSWORD=$( jq -r ".database.password" $(dirname "$0")/config.prod.json )
    POSTGRES_PASSWORD=$( jq -r ".database.manager_password" $(dirname "$0")/config.prod.json )
    REPLICATION_PASSWORD=$( jq -r ".database.replication_password" $(dirname "$0")/config.prod.json )   
    
    MANAGER_IP=$( jq -r ".server.instances.manager.ip" $(dirname "$0")/config.prod.json )
    PRIMARY_IP=$( jq -r ".server.instances.primary.ip" $(dirname "$0")/config.prod.json )
    STANDBY_IP=$( jq -r ".server.instances.standby[0].ip" $(dirname "$0")/config.prod.json )
    BACKUP_IP=$( jq -r ".server.instances.backup.ip" $(dirname "$0")/config.prod.json )
    BUILD_IP=$( jq -r ".server.instances.build.ip" $(dirname "$0")/config.prod.json )
    GATEWAY_IP=$( jq -r ".server.gateway_ip" $(dirname "$0")/config.prod.json )

    MANAGER_NAME=$( jq -r ".server.instances.manager.name" $(dirname "$0")/config.prod.json )
    PRIMARY_NAME=$( jq -r ".server.instances.primary.name" $(dirname "$0")/config.prod.json )
    BACKUP_NAME=$( jq -r ".server.instances.backup.name" $(dirname "$0")/config.prod.json )
    STANDBY_NAME=$( jq -r ".server.instances.standby[0].name" $(dirname "$0")/config.prod.json)
    BUILD_NAME=$( jq -r ".server.instances.build.name" $(dirname "$0")/config.prod.json )   
    CIPHER_PASSWORD=$( jq -r ".database.cipher_password" $(dirname "$0")/config.prod.json )

    FAILGUARD_DEBUG=$( jq -r ".debug" $(dirname "$0")/config.prod.json )
else
    read -p "Enter VPC ID : " VPC_ID
    read -p "Enter Region : " REGION
    read -p "Enter SSH Key ID : " SSH_KEY_ID
    read -p "Enter Bearer Token : " BEARER_TOKEN
    read -p "Enter your DB Name : " DB_NAME
    read -p "Enter your Cluster Name : " CLUSTER_NAME
    read -p "Enter your Server Name : " SERVER_NAME
    read -p "Enter your Domain : " DOMAIN
    read -p "Enter your Private Gateway IP : " GATEWAY_IP

    # Host credentials
    read -p "Enter a username : " USERNAME
    read -s -p "Enter password : " NEW_PASSWORD
    printf '\n'

    # Postgres Manager Surperuser credentials
    read -s -p "Create a postgres (superuser) password for your manager db : " POSTGRES_MANAGER_PASSWORD
    printf '\n'

    # Postgres Primary Superuser credentials
    read -s -p "Create a postgres (superuser) password for your primary db : " POSTGRES_PASSWORD
    printf '\n'

    # Postgres Replication credentials
    read -s -p "Create a replication user password : " REPLICATION_PASSWORD
    printf '\n'

    # Generate a cipher password
    CIPHER_PASSWORD=$(openssl rand -base64 48)
    FAILGUARD_DEBUG=false
fi

# Initial Build
init_build()
{
    build_droplets
    build_pgbackrest
    
    # Install pgbackrest on each machine
    if $FAILGUARD_DEBUG; then
        echo "Skipping pgbackrest install (DEBUG MODE)"
    else
        install_pgbackrest $BACKUP_IP
        install_pgbackrest $PRIMARY_IP
        install_pgbackrest $STANDBY_IP
    fi
}

init_manager()
{
    echo "Manager Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} 'bash -s' <<EOT
USERNAME=$USERNAME; 
NEW_PASSWORD="$NEW_PASSWORD"; 
GATEWAY_IP=$GATEWAY_IP; 
PRIMARY_IP=$PRIMARY_IP; 
PRIMARY_NAME=$PRIMARY_NAME; 
BACKUP_IP=$BACKUP_IP; 
BACKUP_NAME=$BACKUP_NAME; 
STANDBY_IP=$STANDBY_IP; 
STANDBY_NAME=$STANDBY_NAME; 
MANAGER_IP=$MANAGER_IP; 
MANAGER_NAME=$MANAGER_NAME; 
POSTGRES_PASSWORD="$POSTGRES_MANAGER_PASSWORD";
$(< $(dirname "$0")/utils/db_setup.sh); 
$(< $(dirname "$0")/utils/initial_setup.sh); 
$(< $(dirname "$0")/utils/private_setup.sh); 
$(< $(dirname "$0")/utils/do_patches.sh); 
$(< $(dirname "$0")/main/initial_setup.sh); 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/manager_tooling.sh); 
$(< $(dirname "$0")/manager_init.sh);
EOT
}

init_primary()
{
    echo "Primary Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} 'bash -s' <<EOT
USERNAME=$USERNAME; 
NEW_PASSWORD="$NEW_PASSWORD"; 
SERVER_NAME=$SERVER_NAME;
DB_NAME=$DB_NAME; 
POSTGRES_PASSWORD="$POSTGRES_PASSWORD"; 
GATEWAY_IP=$GATEWAY_IP; 
MANAGER_IP=$MANAGER_IP; 
MANAGER_NAME=$MANAGER_NAME; 
PRIMARY_IP=$PRIMARY_IP; 
PRIMARY_NAME=$PRIMARY_NAME; 
BACKUP_IP=$BACKUP_IP; 
BACKUP_NAME=$BACKUP_NAME; 
STANDBY_IP=$STANDBY_IP; 
STANDBY_NAME=$STANDBY_NAME; 
CLUSTER_NAME=$CLUSTER_NAME; 
$(< $(dirname "$0")/utils/db_setup.sh); 
$(< $(dirname "$0")/utils/initial_setup.sh); 
$(< $(dirname "$0")/utils/private_setup.sh); 
$(< $(dirname "$0")/utils/do_patches.sh);
$(< $(dirname "$0")/main/build_setup.sh);
$(< $(dirname "$0")/main/initial_setup.sh); 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/primary_tooling.sh); 
$(< $(dirname "$0")/primary_init.sh);
EOT
}

init_backup()
{
    echo "Backup Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} 'bash -s' <<EOT
USERNAME=$USERNAME; 
NEW_PASSWORD="$NEW_PASSWORD"; 
GATEWAY_IP=$GATEWAY_IP; 
PRIMARY_IP=$PRIMARY_IP; 
PRIMARY_NAME=$PRIMARY_NAME; 
BACKUP_IP=$BACKUP_IP; 
BACKUP_NAME=$BACKUP_NAME; 
STANDBY_IP=$STANDBY_IP; 
STANDBY_NAME=$STANDBY_NAME; 
MANAGER_IP=$MANAGER_IP; 
MANAGER_NAME=$MANAGER_NAME; 
CLUSTER_NAME=$CLUSTER_NAME; 
$(< $(dirname "$0")/utils/db_setup.sh); 
$(< $(dirname "$0")/utils/initial_setup.sh); 
$(< $(dirname "$0")/utils/private_setup.sh); 
$(< $(dirname "$0")/utils/do_patches.sh); 
$(< $(dirname "$0")/main/build_setup.sh); 
$(< $(dirname "$0")/main/initial_setup.sh); 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/backup_tooling.sh); 
$(< $(dirname "$0")/backup_init.sh);
EOT
}

init_standby()
{
    echo "Standby Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${STANDBY_IP} 'bash -s' <<EOT
USERNAME=$USERNAME; 
NEW_PASSWORD="$NEW_PASSWORD";  
SERVER_NAME=$SERVER_NAME;
DB_NAME=$DB_NAME; 
POSTGRES_PASSWORD="$POSTGRES_PASSWORD"; 
GATEWAY_IP=$GATEWAY_IP; 
PRIMARY_IP=$PRIMARY_IP; 
PRIMARY_NAME=$PRIMARY_NAME; 
BACKUP_IP=$BACKUP_IP; 
BACKUP_NAME=$BACKUP_NAME; 
STANDBY_IP=$STANDBY_IP; 
STANDBY_NAME=$STANDBY_NAME; 
MANAGER_IP=$MANAGER_IP; 
MANAGER_NAME=$MANAGER_NAME; 
CLUSTER_NAME=$CLUSTER_NAME; 
REPLICATION_PASSWORD="$REPLICATION_PASSWORD"; 
$(< $(dirname "$0")/utils/db_setup.sh); 
$(< $(dirname "$0")/utils/initial_setup.sh); 
$(< $(dirname "$0")/utils/private_setup.sh); 
$(< $(dirname "$0")/utils/do_patches.sh); 
$(< $(dirname "$0")/main/build_setup.sh); 
$(< $(dirname "$0")/main/initial_setup.sh); 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/standby_tooling.sh); 
$(< $(dirname "$0")/standby_init.sh);
EOT
}

setup_backup()
{
    echo "Backup Second Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} 'bash -s' <<EOT
PRIMARY_NAME=$PRIMARY_NAME; 
STANDBY_IP=$STANDBY_IP; 
STANDBY_NAME=$STANDBY_NAME; 
CLUSTER_NAME=$CLUSTER_NAME; 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/backup_tooling.sh); 
$(< $(dirname "$0")/backup_setup.sh);
EOT
}

setup_primary()
{
    echo "Primary Second Setup Started"
    ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} 'bash -s' <<EOT
BACKUP_IP=$BACKUP_IP; 
BACKUP_NAME=$BACKUP_NAME; 
CIPHER_PASSWORD="$CIPHER_PASSWORD"; 
CLUSTER_NAME=$CLUSTER_NAME; 
STANDBY_IP=$STANDBY_IP; 
REPLICATION_PASSWORD="$REPLICATION_PASSWORD"; 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/primary_tooling.sh); 
$(< $(dirname "$0")/primary_setup.sh);
EOT
}

start_primary()
{
    echo "Starting Primary"
    ssh -q -A -o "StrictHostKeyChecking no" root@${PRIMARY_IP} 'bash -s' <<EOT
CLUSTER_NAME=$CLUSTER_NAME; 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/primary_start.sh);
EOT
}

start_standby()
{
    echo "Starting Standby"
    ssh -q -A -o "StrictHostKeyChecking no" root@${STANDBY_IP} 'bash -s' <<EOT
CLUSTER_NAME=$CLUSTER_NAME; 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/standby_start.sh);
EOT
}

start_backup()
{
    echo "Starting Backup"
    ssh -q -A -o "StrictHostKeyChecking no" root@${BACKUP_IP} 'bash -s' <<EOT
CLUSTER_NAME=$CLUSTER_NAME; 
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/backup_start.sh);
EOT
}

finish_manager()
{
    echo "Finalizing Manager"
    ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} 'bash -s' <<EOT
CLUSTER_NAME=$CLUSTER_NAME;
PRIMARY_IP=$PRIMARY_IP;
PRIMARY_NAME=$PRIMARY_NAME;
BACKUP_IP=$BACKUP_IP;
BACKUP_NAME=$BACKUP_NAME;
STANDBY_IP=$STANDBY_IP;
STANDBY_NAME=$STANDBY_NAME;
MANAGER_IP=$MANAGER_IP;
MANAGER_NAME=$MANAGER_NAME;
$(< $(dirname "$0")/main/failguard_utils.sh); 
$(< $(dirname "$0")/main/manager_tooling.sh); 
$(< $(dirname "$0")/manager_setup.sh);
EOT
}

# Install pgbackrest on each machine
if $FAILGUARD_DEBUG; then
    init_build
    init_manager
    self_destruct
else
    init_build
    init_manager
    init_primary
    init_backup
    init_standby
    setup_backup
    setup_primary
    start_primary
    start_standby
    start_backup
    finish_manager
    self_destruct
fi

