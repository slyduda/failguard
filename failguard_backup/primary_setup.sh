#!/bin/sh
# -------------------------- #
#   Primary Cluster Setup -  #
# -------------------------- #

echo "What would you like to name your cluster?"
read clusterName

touch .etc/pgbackrest/pgbackrest.conf

cipherPass=$(openssl rand -base64 48)
echo "Your encryption password is: $cipherPass" 

> /etc/pgbackrest/pgbackrest.conf
echo "[$clusterName]
pg1-path=/var/lib/postgresql/12/main

[global]
repo1-cipher-pass=$cipherPass
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[global:archive-push]
compress-level=3" >> /etc/pgbackrest/pgbackrest.conf

sudo mkdir -p /var/lib/pgbackrest
sudo chmod 750 /var/lib/pgbackrest
sudo chown postgres:postgres /var/lib/pgbackrest

# -------------------------- #
#   Primary Cluster Config   #
# -------------------------- #

sed -i "s/#archive_command.*/archive_command = 'pgbackrest --stanza=$clusterName archive-push %p'/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#archive_mode.*/archive_mode = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#max_wal_senders.*/max_wal_senders = 3/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#wal_level.*/wal_level = replica/g" /etc/postgresql/12/main/postgresql.conf

sudo pg_ctlcluster 12 $clusterName restart


# SKIP THESE IF RUNNING DEDICATED BACKUP SERVER

# Create the stanze
# sudo -u postgres pgbackrest --stanza=$clusterName --log-level-console=info stanza-create

# Find a way to check response
#sudo -u postgres pgbackrest --stanza=$clusterName --log-level-console=info check


# -------------------------- #
#  - Primary Cluster Auth -  #
# -------------------------- #

# Create pg-primary host key pair
# TODO: Check if keypair already exists
sudo -u postgres mkdir -m 750 -p /var/lib/postgresql/.ssh
sudo -u postgres ssh-keygen -f /var/lib/postgresql/.ssh/id_rsa -t rsa -b 4096 -N ""

# -------------------------- #
#   HANG HERE@@@@@@@@@@@@@@  #
# -------------------------- #

# Copy repository public key to pg-primary
(echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
       echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
       sudo ssh root@pg-backup cat /home/pgbackrest/.ssh/id_rsa.pub) | \
       sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys


# Test connection from pg-primary to pg-backup
sudo -u postgres ssh -q pgbackrest@repository exit
if [ $? -ne 0 ]; then
    exit
else
    echo "successfully connected to the backup server!"

# If both connections are successful continue

# -------------------------- #
#  - Backup Cluster Repo --  #
# -------------------------- #


# Configure repo1-host/repo1-host-user
> /etc/pgbackrest/pgbackrest.conf
echo "[$clusterName]
pg1-path=/var/lib/postgresql/12/main

[global]
repo1-host=pg-backup
repo1-cipher-pass=$cipherPass
repo1-cipher-type=aes-256-cbc
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
log-level-file=detail

[global:archive-push]
compress-level=3" >> /etc/pgbackrest/pgbackrest.conf


# Test connection from pg-primary to pg-backup
sudo -u postgres ssh pgbackrest@pg-backup

# -------------------------- #
#   HANG HERE@@@@@@@@@@@@@@  #
# -------------------------- #


echo "Please add a password for replication user"
read replicationPassword

#  Create replication user
sudo -u postgres psql -c "create user replicator password '$replicationPassword' replication";

# Create pg_hba.conf entry for replication user
sudo -u postgres sh -c 'echo "host    replication     replicator      $standbyIp/32           md5" >> /etc/postgresql/12/demo/pg_hba.conf'

# Reload with new conf
sudo pg_ctlcluster 12 $clusterName reload
