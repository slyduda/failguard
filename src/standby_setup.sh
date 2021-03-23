#!/bin/sh
source $(dirname "$0")/utils/db_setup.sh
source $(dirname "$0")/utils/initial_setup.sh
source $(dirname "$0")/utils/private_setup.sh

source $(dirname "$0")/main/initial_setup.sh
source $(dirname "$0")/main/failguard_utils.sh 
source $(dirname "$0")/main/build_setup.sh
source $(dirname "$0")/main/standby_tooling.sh

sudo apt-get install jq

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
set_replica_streaming_standby_config $PRIMARY_NAME $BACKUP_NAME $REPLICATION_PASSWORD $CLUSTER_NAME

# Share Standby Key with Backup 
send_postgres_public_key $BACKUP_NAME

# Exit