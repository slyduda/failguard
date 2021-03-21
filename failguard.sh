#!/bin/sh
source $(dirname "$0")/db_setup.sh
source $(dirname "$0")/initial_setup.sh
source $(dirname "$0")/private_setup.sh
source $(dirname "$0")/failguard_backup/utils.sh
source $(dirname "$0")/failguard_backup/backup_setup.sh
source $(dirname "$0")/failguard_backup/initial_setup.sh
source $(dirname "$0")/failguard_backup/primary_setup.sh
source $(dirname "$0")/failguard_backup/standby_setup.sh

# Get the Private IP of the current machine (BUILD)
BUILD_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)

# Ask for user info
read -p "Enter username : " username
read -s -p "Enter password : " password

# Get db config info
read -p "Enter database name : " db_name
read -s -p "Create a postgres (superuser) password : " postgres_password
read -s -p "Create a replication user password : " REPLICATION_PASSWORD

# Get the IP and name info for all servers
# This will be automated and stored in the management DB later
read -p "Enter the manager private IP : " MANAGER_IP
read -p "Enter the manager name : " MANAGER_NAME
read -p "Enter the primary private IP : " PRIMARY_IP
read -p "Enter the primary name : " PRIMARY_NAME
read -p "Enter the backup private IP : " BACKUP_IP
read -p "Enter the backup name : " BACKUP_NAME
read -p "Enter the standby private IP : " STANDBY_IP
read -p "Enter the standby name : " STANDBY_NAME

# Create Cluster Config Info
# Add more config here later
read -p "Enter the cluster name : " CLUSTER_NAME
CIPHER_PASSWORD=$(openssl rand -base64 48)

manager_setup()
{
    # SSH to Manager Server
    configure_server $username $password
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME
    # Exit
}


primary_setup()
{
    # SSH to Primary Server
    
    # Initial Config
    configure_private_droplet
    configure_server $username $password
    
    # Create Hosts and Keys
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
    create_ssh_keys postgres
    
    # Install postgres and pgbackrest
    install_postgres $db_name $postgres_password
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
    configure_server $username $password
    
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
    configure_server $username $password

    # Create Hosts and Keys
    create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME
    create_ssh_keys postgres

    # Install postgres and pgbackrest
    install_postgres $db_name $postgres_password
    install_pgbackrest $BUILD_IP

    # Create pgbackrest config
    create_pgbackrest_config postgres
    create_pgbackrest_repository postgres
    set_streaming_standby_config $PRIMARY_NAME $BACKUP_NAME $CLUSTER_NAME $REPLICATION_PASSWORD
    
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
    set_backup_standby_primary_config $CLUSTER_NAME $CIPHER_PASSWORD $BACKUP_NAME
    set_replica_streaming_primary_config $CLUSTER_NAME $STANDBY_IP $REPLICATION_PASSWORD 
    # Exit
}


# manager_setup
primary_setup
# backup_setup
# primary_auth
# standby_setup
# finish_backup_setup
# finish_primary_setup