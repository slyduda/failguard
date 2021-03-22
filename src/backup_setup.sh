#!/bin/sh
source $(dirname "$0")/util/db_setup.sh
source $(dirname "$0")/util/initial_setup.sh
source $(dirname "$0")/util/private_setup.sh

source $(dirname "$0")/main/build_setup.sh
source $(dirname "$0")/main/backup_tooling.sh

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
