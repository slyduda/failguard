#!/bin/sh
# -------------------------- #
#   Postgres Backup Setup    #
# -------------------------- #

# Configuring pgbackrest
# Get IP addresses 
# Revise later to potentially make dynamic
echo "What is the IP of your primary database?"
read primaryIp
echo "What is the IP of your standby database?"
read standbyIp
echo "What is the IP of your backup database?"
read backupIp

# Add hard coded variables to file
echo "$primaryIp pg-primary
$standbyIp pg-standby-1
$backupIp pg-backup" >> /etc/cloud/templates/hosts.debian.tmpl

# Configure listen addresses to make the DB available to all hosts
sed -i "s/#listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/main/postgresql.conf

# Configure the postgres to listen to all ports (We can change this later if we want)
echo 'host    all             all             0.0.0.0/0               md5
host    all             all             ::0/0                   md5' >> /etc/postgresql/12/main/pg_hba.conf
