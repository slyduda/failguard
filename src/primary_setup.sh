#!/bin/sh
source $(dirname "$0")/util/db_setup.sh
source $(dirname "$0")/util/initial_setup.sh
source $(dirname "$0")/util/private_setup.sh

source $(dirname "$0")/main/build_setup.sh
source $(dirname "$0")/main/primary_tooling.sh

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
set_archiving_primary_config $CLUSTER_NAME

# create_pgbackrest_repository postgres # Only for local repository
# restart_cluster $CLUSTER_NAME

# Exit