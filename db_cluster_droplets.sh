#!/bin/sh
#Update the server
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# -------------------------- #
# ------ Initial Setup ----- #
# -------------------------- #

# Create a new user for security purposes.
echo "What do you want to name your new user?"
read username

echo "Please add a password"
read password

if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" "$username"
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system."
	exit 2
fi

# Give the user sudo permissions
usermod -aG sudo $username

# Configure Firewall
ufw allow ssh
ufw allow 5432
ufw enable

# Allow the server to be accessible via password if one exists
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
service ssh restart

# -------------------------- #
#   Private Droplet Config   #
# -------------------------- #

apt install net-tools
route -n

echo "What is your default Gateway IP listed above?"
read gatewayIp
# Specific to Digital Ocean
ip route add 169.254.169.254 via $gatewayIp dev eth0

echo "What is the Private IP of this Droplet?"
read privateIp
ip route change default via $privateIp

echo "What is the Private IP of your Gatewatay?"
read privateGatewayIp

sed -i '/gateway4:/d' /etc/netplan/50-cloud-init.yaml
sed -i '25,35 s|search: \[\]|search: \[\] \
            routes: \
            -   to: 0.0.0.0\/0  \
                via: '"$privateGatewayIp"'|gi' /etc/netplan/50-cloud-init.yaml

netplan apply -debug

echo "Waiting a few seconds before testing network..."
sleep 3

if ping -q -c 4 google.com > /dev/null; then
    echo "This droplet can reach other networks."
else
    echo "Network failure."
    exit 1
fi

ip route get 8.8.8.8 | sed 's/^.*src \([^ ]*\).*$/\1/;q'

# -------------------------- #
#  Postgres Database Setup   #
# -------------------------- #

apt install postgresql postgresql-contrib

echo "What password would you like to give to the superuser of the database (postgres)?"
read postgresPassword

echo "What would you like to call your database?"
read dbname

sudo -u postgres psql << EOF
ALTER USER postgres PASSWORD '$postgresPassword';
CREATE DATABASE $dbname;
EOF



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

sed -i "s/#archive_command.*/archive_command = 'pgbackrest --stanza=demo archive-push %p'/g" /etc/postgresql/12/main/postgresql.conf
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
#   Backup Cluster Config -  #
# -------------------------- #

# Create a pgbackrest user to make it easier
sudo adduser --disabled-password --gecos "" pgbackrest

# Copy pgBackRest binary from build host
sudo scp $buildHost:/build/pgbackrest-release-2.32/src/pgbackrest /usr/bin
sudo chmod 755 /usr/bin/pgbackrest

# Create pgBackRest configuration file and directories
sudo mkdir -p -m 770 /var/log/pgbackrest
sudo chown pgbackrest:pgbackrest /var/log/pgbackrest
sudo mkdir -p /etc/pgbackrest
sudo mkdir -p /etc/pgbackrest/conf.d
sudo touch /etc/pgbackrest/pgbackrest.conf
sudo chmod 640 /etc/pgbackrest/pgbackrest.conf
sudo chown pgbackrest:pgbackrest /etc/pgbackrest/pgbackrest.conf

# Create the pgBackRest repository
sudo mkdir -p /var/lib/pgbackrest
sudo chmod 750 /var/lib/pgbackrest
sudo chown pgbackrest:pgbackrest /var/lib/pgbackrest

# -------------------------- #
#  - Backup Cluster Auth --  #
# -------------------------- #

# Threads between two servers
# The complicated part about this is keeping a list of your cluster and making sure the proper threads are run.

# Create repository host key pair
# Check if keypair already exists
sudo -u pgbackrest mkdir -m 750 /home/pgbackrest/.ssh
sudo -u pgbackrest ssh-keygen -f /home/pgbackrest/.ssh/id_rsa -t rsa -b 4096 -N ""

# Create pg-primary host key pair
# TODO: Check if keypair already exists
sudo -u postgres mkdir -m 750 -p /var/lib/postgresql/.ssh
sudo -u postgres ssh-keygen -f /var/lib/postgresql/.ssh/id_rsa -t rsa -b 4096 -N ""

# Copy pg-primary public key to pg-backup
(echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
       echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
       sudo ssh root@pg-primary cat /var/lib/postgresql/.ssh/id_rsa.pub) | \
       sudo -u pgbackrest tee -a /home/pgbackrest/.ssh/authorized_keys

# Copy repository public key to pg-primary
(echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
       echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
       sudo ssh root@repository cat /home/pgbackrest/.ssh/id_rsa.pub) | \
       sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys

# Test connection from pg-backup to pg-primary
sudo -u pgbackrest ssh -q postgres@pg-primary exit
if [ $? -ne 0 ]; then
    exit
else
    echo "successfully connected to the primary server!"

# Test connection from pg-primary to pg-backup
sudo -u postgres ssh -q pgbackrest@repository exit
if [ $? -ne 0 ]; then
    exit
else
    echo "successfully connected to the backup server!"


# -------------------------- #
#  - Backup Cluster Repo --  #
# -------------------------- #

# Threads between two servers

# Configure pg1-host/pg1-host-user and pg1-path
> /etc/pgbackrest/pgbackrest.conf
echo "[$clusterName]
pg1-host=pg-primary
pg1-path=/var/lib/postgresql/12/main

[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
start-fast=y" >> /etc/pgbackrest/pgbackrest.conf

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

# Test connection from pg-backup to pg-primary
sudo -u pgbackrest ssh postgres@pg-primary

# Test connection from pg-primary to pg-backup
sudo -u postgres ssh pgbackrest@repository
