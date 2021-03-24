#!/bin/sh
source $(dirname "$0")/utils/db_setup.sh
source $(dirname "$0")/utils/initial_setup.sh
source $(dirname "$0")/utils/private_setup.sh
source $(dirname "$0")/utils/do_patches.sh

source $(dirname "$0")/main/initial_setup.sh
source $(dirname "$0")/main/failguard_utils.sh 
source $(dirname "$0")/main/build_setup.sh
source $(dirname "$0")/main/backup_tooling.sh

do_patch_root_login
do_patch_resolved

sudo apt-get update -qq -y
sudo apt-get upgrade -qq -y

# Initial Config
configure_private_droplet $GATEWAY_IP
configure_server $USERNAME $PASSWORD

# Create pgbackrest config
create_pgbackrest_user
create_pgbackrest_config pgbackrest
create_pgbackrest_repository pgbackrest
set_backup_config $PRIMARY_NAME $CLUSTER_NAME

# Create Hosts and Keys
create_cluster_hosts $MANAGER_IP $MANAGER_NAME $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 
create_ssh_keys pgbackrest

# Share Backup Key with Primary 
send_pgbackrest_public_key $PRIMARY_IP
