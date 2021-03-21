#!/bin/sh
create_pgbackrest_user()
{
    # Create a pgbackrest user to make it easier
    sudo adduser --disabled-password --gecos "" pgbackrest
}



set_backup_config()
{
    # Configure pg1-host/pg1-host-user and pg1-path
    PRIMARY_NAME=$1
    CLUSTER_NAME=$3

    > /etc/pgbackrest/pgbackrest.conf
    echo "[$CLUSTER_NAME]
    pg1-host=$PRIMARY_NAME
    pg1-path=/var/lib/postgresql/12/main

    [global]
    repo1-path=/var/lib/pgbackrest
    repo1-retention-full=2
    start-fast=y" >> /etc/pgbackrest/pgbackrest.conf

    # Test connection from pg-backup to pg-primary
    sudo -u pgbackrest ssh postgres@$PRIMARY_NAME
}

set_backup_standby_backup_config()
{
    PRIMARY_NAME=$1
    STANDBY_NAME=$2
    CLUSTER_NAME=$3
    # On the backup
    > /etc/pgbackrest/pgbackrest.conf
    echo "[$CLUSTER_NAME]
    pg1-host=$PRIMARY_NAME
    pg1-path=/var/lib/postgresql/12/main
    pg2-host=$STANDBY_NAME
    pg2-path=/var/lib/postgresql/12/main

    [global]
    backup-standby=y
    process-max=3
    repo1-path=/var/lib/pgbackrest
    repo1-retention-full=2
    start-fast=y" >> /etc/pgbackrest/pgbackrest.conf
}
