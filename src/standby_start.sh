#!/bin/sh
# source $(dirname "$0")/main/failguard_utils.sh

update_standby_stanza $CLUSTER_NAME # To get any changes
start_cluster $CLUSTER_NAME