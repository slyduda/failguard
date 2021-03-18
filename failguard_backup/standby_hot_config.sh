#!/bin/sh
# -------------------------- #
# --  Standby Hot Config --  #
# -------------------------- #

# Configure repo1-host/repo1-host-user
> /etc/pgbackrest/pgbackrest.conf
echo "[$clusterName]
pg1-path=/var/lib/postgresql/12/demo

[global]
log-level-file=detail
repo1-host=repository" >> /etc/pgbackrest/pgbackrest.conf

# Create cluster
sudo pg_createcluster 12 $clusterName

# Restore the demo standby cluster
sudo -u postgres pgbackrest --stanza=$clusterName --delta --type=standby restore
sudo -u postgres cat /var/lib/postgresql/12/demo/postgresql.auto.conf


# Configure PostgreSQL
sed -i "s/#archive_command.*/archive_command = 'pgbackrest --stanza=$clusterName archive-push %p'/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#archive_mode.*/archive_mode = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#hot_standby.*/hot_standby = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#log_filename.*/log_filename = 'postgresql.log'/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#max_wal_senders.*/max_wal_senders = 3/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#wal_level.*/wal_level = replica/g" /etc/postgresql/12/main/postgresql.conf

# Probably should add all addresses if private
# sed -i "s/#listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf

# Start PostgreSQL
sudo pg_ctlcluster 12 $clusterName start

# Examine the PostgreSQL log output for log messages indicating success
# sudo -u postgres cat /var/log/postgresql/postgresql-12-demo.log
