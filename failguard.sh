#!/bin/sh

# Get the Private IP of the current machine (BUILD)
PRIVATE_IP_BUILD=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)

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
    configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
    # Exit
}


primary_setup()
{
    # SSH to Primary Server
    configure_server $username $password
    configure_database_server $db_name $postgres_password
    configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
    configure_primary_postgresql $CLUSTER_NAME
    create_primary_keys
    # Exit
}

backup_setup() 
{
    # SSH to Backup Server
    configure_server $username $password
    configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
    create_backup_config $PRIMARY_NAME $CLUSTER_NAME
    create_backup_keys $PRIMARY_NAME
    # Exit
}

primary_auth()
{
    # SSH to Primary Server
    copy_primary_key_to_backup $BACKUP_NAME
    create_primary_backup_config $CLUSTER_NAME $CIPHER_PASSWORD $BACKUP_NAME
    # Exit
}

standby_setup() 
{
    # SSH to Standby Server
    configure_server $username $password
    configure_database_server $db_name $postgres_password
    configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 

    configure_standby_server $PRIVATE_IP_BUILD
    copy_standby_key $BACKUP_NAME
    create_standby_streaming_config $PRIMARY_NAME $BACKUP_NAME $CLUSTER_NAME $REPLICATION_PASSWORD
    # Exit
}

connect_backup_to_standby() 
{
    # SSH to Standby Server
    create_backup_standby_config $PRIMARY_NAME $STANDBY_IP $CLUSTER_NAME
    copy_backup_key $STANDBY_NAME
    # Exit
}

connect_primary_to_standby()
{
    # SSH to Primary Server
    create_primary_standby_config $CLUSTER_NAME $STANDBY_IP $REPLICATION_PASSWORD 
    # Exit
}