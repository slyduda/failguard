#!/bin/sh
# source $(dirname "$0")/main/failguard_utils.sh

create_stanza $CLUSTER_NAME pgbackrest
backup_cluster $CLUSTER_NAME