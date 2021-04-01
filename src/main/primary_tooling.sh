#!/bin/sh

set_local_repository_primary_config()
{
    echo "Setting local repository config"
    cluster_name=$1
    cipher_password=$2

    > /etc/pgbackrest/pgbackrest.conf
    echo "[$cluster_name]
pg1-path=/var/lib/postgresql/12/$cluster_name

[global]
# repo1-cipher-pass=$cipher_password
# repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[global:archive-push]
compress-level=3" >> /etc/pgbackrest/pgbackrest.conf
}

set_archiving_primary_config() 
{
    echo "Setting archiving config"
    cluster_name=$1
    sed -i "s/.*archive_command.*/archive_command = 'pgbackrest --stanza=$cluster_name archive-push %p'/g" /etc/postgresql/12/$cluster_name/postgresql.conf
    sed -i "s/.*archive_mode.*/archive_mode = on/g" /etc/postgresql/12/$cluster_name/postgresql.conf
    sed -i "s/.*listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/$cluster_name/postgresql.conf
    sed -i "s/.*log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/$cluster_name/postgresql.conf
    sed -i "s/.*max_wal_senders.*/max_wal_senders = 3/g" /etc/postgresql/12/$cluster_name/postgresql.conf
    sed -i "s/.*wal_level.*/wal_level = replica/g" /etc/postgresql/12/$cluster_name/postgresql.conf
}

# SKIP THESE IF RUNNING DEDICATED BACKUP SERVER

# Create the stanze
# sudo -u postgres pgbackrest --stanza=$clusterName --log-level-console=info stanza-create

# Find a way to check response
#sudo -u postgres pgbackrest --stanza=$clusterName --log-level-console=info check

set_replica_streaming_primary_config()
{
    echo "Setting replica streaming config"
    standby_ip=$1
    replication_password=$2
    cluster_name=$3
    dqt='"'
    #  Create replication user
    sudo -u postgres psql -c "create user replicator password '$replication_password' replication;"

    # Create pg_hba.conf entry for replication user
    sudo -u postgres sh -c "echo ${dqt}host    replication     replicator      $standby_ip/32          md5${dqt} >> /etc/postgresql/12/$cluster_name/pg_hba.conf"
}

set_backup_standby_primary_config()
{
    echo "Setting backup standby config"
    # Configure repo1-host/repo1-host-user
    backup_host=$1
    cipher_password=$2
    cluster_name=$3

    > /etc/pgbackrest/pgbackrest.conf
    echo "[$cluster_name]
pg1-path=/var/lib/postgresql/12/$cluster_name

[global]
repo1-host=$backup_host
# repo1-cipher-pass=$cipher_password
# repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
log-level-file=detail

[global:archive-push]
compress-level=3" >> /etc/pgbackrest/pgbackrest.conf
}


