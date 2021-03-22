#!/bin/sh
source $(dirname "$0")/util/db_setup.sh
source $(dirname "$0")/util/initial_setup.sh
source $(dirname "$0")/util/private_setup.sh

source $(dirname "$0")/main/manager_tooling.sh

# Initial Config
configure_private_droplet
configure_server $USERNAME $PASSWORD

# Create Hosts
create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME

# Install postgres
install_postgres $DB_NAME $POSTGRES_PASSWORD
