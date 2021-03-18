#!/bin/sh
# By default failguard creates private database 
# servers that cannot be accessed from outside of your VPN.

# Failguard currently works with Digital Ocean to help deploy 
# primary, backup, and replica servers for a single cluster.

# In order to complete this process you will need to deploy 
# four servers at a minimum. The server types are as follows:

# $name-db - (pg-primary) - Your main database instance that 
# interacts with your applications.

# $name-standby-$id - (pg-standby-$id) - Your replica database 
# in case your main goes offline.

# db-backup - (pg-backup) - Your main backup server.

# $name-disposable - A disposable instance that will be used to 
# facilitate the installation of pgbackrest

# At a later point in time, this project will support instancing 
# multiple standby servers along with, using additional clusters 
# on the same backup server

# Ask user what their username should be
# Ask user what their password should be

# Ask for user info
read -p "Enter username : " username
read -s -p "Enter password : " password

# Get db config info
read -p "Enter database name : " db_name
read -s -p "Create a postgres (superuser) password : " postgres_password
read -s -p "Create a replication user password : " REPLICATION_PASSWORD

PRIVATE_IP_BUILD=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)

read -p "Enter the manager private IP : " MANAGER_IP
read -p "Enter the manager name : " MANAGER_NAME
read -p "Enter the primary private IP : " PRIMARY_IP
read -p "Enter the primary name : " PRIMARY_NAME
read -p "Enter the backup private IP : " BACKUP_IP
read -p "Enter the backup name : " BACKUP_NAME
read -p "Enter the standby private IP : " STANDBY_IP
read -p "Enter the standby name : " STANDBY_NAME

read -p "Enter the cluster name : " CLUSTER_NAME
CIPHER_PASSWORD=$(openssl rand -base64 48)

# SSH to Manager Server
configure_server $username $password
configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
# Exit

# SSH to Primary Server
configure_server $username $password
configure_database_server $db_name $postgres_password
configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
configure_primary_postgresql $CLUSTER_NAME
create_primary_keys
# Exit

# SSH to Backup Server
configure_server $username $password
configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
create_backup_keys
# Exit

# SSH to Primary Server
create_primary_backup_config $CLUSTER_NAME $CIPHER_PASSWORD $BACKUP_NAME
# Exit

# SSH to Standby Server
configure_server $username $password
configure_database_server $db_name $postgres_password
configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
configure_backup_server $PRIVATE_IP_BUILD $BACKUP_NAME
create_standby_streaming_config $CLUSTER_NAME
# Exit

# SSH to Backup Server
create_backup_standby_config $CLUSTER_NAME $PRIMARY_NAME $REPLICATION_PASSWORD
# Exit

# SSH to Primary Server
create_primary_standby_config $CLUSTER_NAME $REPLICATION_PASSWORD $STANDBY_IP
# Exit