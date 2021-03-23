#!/bin/sh
source $(dirname "$0")/utils/db_setup.sh
source $(dirname "$0")/utils/initial_setup.sh
source $(dirname "$0")/utils/private_setup.sh

source $(dirname "$0")/main/initial_setup.sh
source $(dirname "$0")/main/failguard_utils.sh 
source $(dirname "$0")/main/manager_tooling.sh

sudo apt-get install jq

# Initial Config
configure_private_droplet
configure_server $USERNAME $PASSWORD

# Create Hosts and Keys
create_cluster_hosts $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME
create_ssh_keys root
fix_ssh_permission root

# Install postgres and add tables
install_postgres failguard $POSTGRES_PASSWORD
create_manager_tables