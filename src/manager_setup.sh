#!/bin/sh
# source $(dirname "$0")/main/failguard_utils.sh
# source $(dirname "$0")/main/manager_tooling.sh

# Insert all items that we should track
CLUSTER_ID=$(insert_failguard_cluster $CLUSTER_NAME)
insert_failguard_server $PRIMARY_IP $PRIMARY_NAME p CLUSTER_ID
insert_failguard_server $STANDBY_IP $STANDBY_NAME s CLUSTER_ID
insert_failguard_server $BACKUP_IP $BACKUP_NAME b CLUSTER_ID
insert_failguard_server $MANAGER_IP $MANAGER_NAME m CLUSTER_ID

# share with all
# send_manager_public_key $PRIMARY_IP postgres
# send_manager_public_key $STANDBY_IP postgres
# send_manager_public_key $BACKUP_IP pgbackrest