#!/bin/sh
create_pgbackrest_user()
{
    # Create a pgbackrest user to make it easier
    sudo adduser --disabled-password --gecos "" pgbackrest
}



set_backup_config()
{
    # Configure pg1-host/pg1-host-user and pg1-path
    primary_name=$1
    cluster_name=$2

    > /etc/pgbackrest/pgbackrest.conf
    echo "[$cluster_name]
pg1-host=$primary_name
pg1-path=/var/lib/postgresql/12/$cluster_name

[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
start-fast=y" >> /etc/pgbackrest/pgbackrest.conf

    # Test connection from pg-backup to pg-primary
    # sudo -u pgbackrest ssh postgres@$PRIMARY_NAME
}

set_backup_standby_backup_config()
{
    primary_name=$1
    standby_name=$2
    cluster_name=$3
    # On the backup
    > /etc/pgbackrest/pgbackrest.conf
    echo "[$cluster_name]
pg1-host=$primary_name
pg1-path=/var/lib/postgresql/12/$cluster_name
pg2-host=$standby_name
pg2-path=/var/lib/postgresql/12/$cluster_name

[global]
backup-standby=y
process-max=3
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
start-fast=y" >> /etc/pgbackrest/pgbackrest.conf
}
