#!/bin/sh

# Revise later to potentially make dynamic
configure_cluster_config() 
{
    PRIMARY_IP=$1
    PRIMARY_NAME=$2
    BACKUP_IP=$3
    BACKUP_NAME=$4
    STANDBY_IP=$5 # Change this to array later
    STANDBY_NAME=$6

    # Add hard coded variables to file
    echo "$PRIMARY_IP $PRIMARY_NAME
    $BACKUP_IP $BACKUP_NAME
    $STANDBY_IP $STANDBY_NAME" >> /etc/cloud/templates/hosts.debian.tmpl
}

configure_cluster_config $PRIMARY_IP $PRIMARY_NAME $BACKUP_IP $BACKUP_NAME $STANDBY_IP $STANDBY_NAME 