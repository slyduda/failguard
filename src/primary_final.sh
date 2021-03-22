#!/bin/sh
source $(dirname "$0")/main/failguard_utils.sh
source $(dirname "$0")/main/primary_tooling.sh


# Share Primary Key with Backup
send_postgres_public_key $BACKUP_NAME

# Configure the Primary Server for Streaming and Standby Backup 
set_backup_standby_primary_config $BACKUP_NAME  $CIPHER_PASSWORD $CLUSTER_NAME 
set_replica_streaming_primary_config  $STANDBY_IP $REPLICATION_PASSWORD $CLUSTER_NAME
# Exit