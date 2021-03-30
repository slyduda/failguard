#!/bin/sh

set_local_repository_primary_config()
{
    CLUSTER_NAME=$1
    CIPHER_PASSWORD=$2

    > /etc/pgbackrest/pgbackrest.conf
    echo "[$CLUSTER_NAME]
pg1-path=/var/lib/postgresql/12/$CLUSTER_NAME

[global]
repo1-cipher-pass=$CIPHER_PASSWORD
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[global:archive-push]
compress-level=3" >> /etc/pgbackrest/pgbackrest.conf
}

set_archiving_primary_config() 
{
    CLUSTER_NAME=$1
    sed -i "s/.*archive_command.*/archive_command = 'pgbackrest --stanza=$CLUSTER_NAME archive-push %p'/g" /etc/postgresql/12/$CLUSTER_NAME/postgresql.conf
    sed -i "s/.*archive_mode.*/archive_mode = on/g" /etc/postgresql/12/$CLUSTER_NAME/postgresql.conf
    sed -i "s/.*listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/$CLUSTER_NAME/postgresql.conf
    sed -i "s/.*log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/$CLUSTER_NAME/postgresql.conf
    sed -i "s/.*max_wal_senders.*/max_wal_senders = 3/g" /etc/postgresql/12/$CLUSTER_NAME/postgresql.conf
    sed -i "s/.*wal_level.*/wal_level = replica/g" /etc/postgresql/12/$CLUSTER_NAME/postgresql.conf
}

# SKIP THESE IF RUNNING DEDICATED BACKUP SERVER

# Create the stanze
# sudo -u postgres pgbackrest --stanza=$clusterName --log-level-console=info stanza-create

# Find a way to check response
#sudo -u postgres pgbackrest --stanza=$clusterName --log-level-console=info check

set_replica_streaming_primary_config()
{

    STANDBY_IP=$1
    REPLICATION_PASSWORD=$2
    CLUSTER_NAME=$3

    #  Create replication user
    sudo -u postgres psql -c "create user replicator password '$REPLICATION_PASSWORD' replication";

    # Create pg_hba.conf entry for replication user
    sudo -u postgres sh -c 'echo "host    replication     replicator      $STANDBY_IP/32           md5" >> /etc/postgresql/12/demo/pg_hba.conf'
}

set_backup_standby_primary_config()
{
    # Configure repo1-host/repo1-host-user
    BACKUP_HOST=$1
    CIPHER_PASSWORD=$2
    CLUSTER_NAME=$3

    > /etc/pgbackrest/pgbackrest.conf
    echo "[$CLUSTER_NAME]
pg1-path=/var/lib/postgresql/12/$CLUSTER_NAME

[global]
repo1-host=$BACKUP_HOST
repo1-cipher-pass=$CIPHER_PASSWORD
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
log-level-file=detail

[global:archive-push]
compress-level=3" >> /etc/pgbackrest/pgbackrest.conf
}


