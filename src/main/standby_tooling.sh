#!/bin/sh
# -------------------------- #
#   Standby Cluster Setup -  #
# -------------------------- #


# -------------------------- #
#  Standby Streaming Config  #
# -------------------------- #

set_replica_streaming_standby_config()
{
       primary_name=$1
       backup_name=$2
       cluster_name=$3
       
       > /etc/pgbackrest/pgbackrest.conf
       echo "[$cluster_name]
pg1-path=/var/lib/postgresql/12/$cluster_name
recovery-option=primary_conninfo=host=$primary_name port=5432 user=replicator

[global]
log-level-file=detail
repo1-host=$backup_name" >> /etc/pgbackrest/pgbackrest.conf

       # sudo pg_ctlcluster 12 $CLUSTER_NAME stop
       # sudo -u postgres pgbackrest --stanza=$CLUSTER_NAME --delta --type=standby restore
       # sudo -u postgres cat /var/lib/postgresql/12/$CLUSTER_NAME/postgresql.auto.conf

       # Start PostgreSQL
       # sudo pg_ctlcluster 12 $CLUSTER_NAME start

       #Examine the PostgreSQL log output for log messages indicating success
       # sudo -u postgres cat /var/log/postgresql/postgresql-12-demo.log

       # Create a new table on the primary
       # Stuff
}

configure_replication_password()
{
       primary_name=$1
       replication_password=$2
       dqt='"'

       # Configure the replication password in the .pgpass file.
       sudo -u postgres sh -c "echo \
              ${dqt}${primary_name}:*:replication:replicator:${replication_password}${dqt} \
              >> /var/lib/postgresql/.pgpass"

       sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass
}