#!/bin/sh
# source $(dirname "$0")/main/failguard_utils.sh
# source $(dirname "$0")/main/backup_tooling.sh

# Share Backup Key with Standby 
send_pgbackrest_public_key $STANDBY_IP

# Configure the Backup Server for Standby Backup 
set_backup_standby_backup_config $PRIMARY_NAME $STANDBY_NAME $CLUSTER_NAME
# Exit