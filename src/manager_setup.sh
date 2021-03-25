#!/bin/sh
# source $(dirname "$0")/utils/db_setup.sh
# source $(dirname "$0")/utils/initial_setup.sh
# source $(dirname "$0")/utils/private_setup.sh
# source $(dirname "$0")/utils/do_patches.sh# 

# source $(dirname "$0")/main/initial_setup.sh
# source $(dirname "$0")/main/failguard_utils.sh 
# source $(dirname "$0")/main/manager_tooling.sh

do_patch_root_login
do_patch_resolved

sudo apt-get update -qq -y
# sudo apt-get upgrade -qq -y

# Initial Config
configure_private_droplet $GATEWAY_IP
configure_server $USERNAME "$NEW_PASSWORD"

# Create Hosts and Keys
create_cluster_hosts $MANAGER_IP $MANAGER_NAME $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME
create_ssh_keys root
fix_ssh_permission root

# Install postgres and add tables
install_postgres failguard $POSTGRES_PASSWORD
create_manager_tables