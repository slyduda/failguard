#!/bin/sh
# source $(dirname "$0")/utils/db_setup.sh
# source $(dirname "$0")/utils/initial_setup.sh
# source $(dirname "$0")/utils/private_setup.sh
# source $(dirname "$0")/utils/do_patches.sh
# 
# source $(dirname "$0")/main/initial_setup.sh
# source $(dirname "$0")/main/failguard_utils.sh 
# source $(dirname "$0")/main/build_setup.sh
# source $(dirname "$0")/main/primary_tooling.sh

EXTERNAL_HOSTNAME=$(hostname)
echo "Securely Logged into: "$EXTERNAL_HOSTNAME

do_patch_root_login
do_patch_resolved

sudo apt-get update -qq -y
# sudo apt-get upgrade -qq -y

# Initial Config
echo "Initial Server Config"
configure_private_droplet $GATEWAY_IP
configure_server $USERNAME "$NEW_PASSWORD"

# Install postgres and pgbackrest
echo "Install Postgres"
install_postgres

echo "Creating $CLUSTER_NAME"
stop_cluster main
pg_lsclusters
sleep 3
create_cluster $CLUSTER_NAME
pg_lsclusters
start_cluster $CLUSTER_NAME
pg_lsclusters
setup_postgres $DB_NAME "$POSTGRES_PASSWORD" $CLUSTER_NAME

# Create pgbackrest config
echo "Creating pgbackrest config"
create_pgbackrest_config postgres
create_pgbackrest_repository postgres
set_archiving_primary_config $CLUSTER_NAME

# Create Hosts and Keys
echo "Creating keys"
create_cluster_hosts $MANAGER_IP $MANAGER_NAME $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
create_ssh_keys postgres

# create_pgbackrest_repository postgres # Only for local repository
# restart_cluster $CLUSTER_NAME