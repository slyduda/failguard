#!/bin/sh
# -------------------------- #
#   Standby Cluster Setup -  #
# -------------------------- #

# Install postgres

sudo scp $buildHost:/build/pgbackrest-release-2.32/src/pgbackrest /usr/bin
sudo chmod 755 /usr/bin/pgbackrest

# Create pgBackRest configuration file and directories
sudo mkdir -p -m 770 /var/log/pgbackrest
sudo chown postgres:postgres /var/log/pgbackrest
sudo mkdir -p /etc/pgbackrest
sudo mkdir -p /etc/pgbackrest/conf.d
sudo touch /etc/pgbackrest/pgbackrest.conf
sudo chmod 640 /etc/pgbackrest/pgbackrest.conf
sudo chown postgres:postgres /etc/pgbackrest/pgbackrest.conf

# Create pg-standby host key pair
sudo -u postgres mkdir -m 750 -p /var/lib/postgresql/.ssh
sudo -u postgres ssh-keygen -f /var/lib/postgresql/.ssh/id_rsa -t rsa -b 4096 -N ""

# Copy pg-standby public key to pg-backup
(echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
       echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
       sudo ssh root@pg-backup cat /home/pgbackrest/.ssh/id_rsa.pub) | \
       sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys


# Test connection from pg-standby to pg-backup
sudo -u postgres ssh pgbackrest@pg-backup

# -------------------------- #
#  Standby Streaming Config  #
# -------------------------- #

> /etc/pgbackrest/pgbackrest.conf
echo "[$clusterName]
[demo]
pg1-path=/var/lib/postgresql/12/main
recovery-option=primary_conninfo=host=pg-primary port=5432 user=replicator

[global]
log-level-file=detail
repo1-host=repository" >> /etc/pgbackrest/pgbackrest.conf

# Configure the replication password in the .pgpass file.
sudo -u postgres sh -c 'echo \
       "pg-primary:*:replication:replicator:$replicationPassword" \
       >> /var/lib/postgresql/.pgpass'

sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass

sudo pg_ctlcluster 12 $clusterName stop
sudo -u postgres pgbackrest --stanza=$clusterName --delta --type=standby restore
sudo -u postgres cat /var/lib/postgresql/12/main/postgresql.auto.conf

# Start PostgreSQL
sudo pg_ctlcluster 12 $clusterName start

#Examine the PostgreSQL log output for log messages indicating success
# sudo -u postgres cat /var/log/postgresql/postgresql-12-demo.log

# Create a new table on the primary
# Stuff