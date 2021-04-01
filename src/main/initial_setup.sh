#!/bin/sh

create_cluster_hosts() 
{
    # Add hard coded variables to file
    echo "# ------ FAILGUARD ------- #" >> /etc/hosts
    echo "# Failguard Manager Host - FGMH" >> /etc/hosts
    echo "$MANAGER_IP $MANAGER_NAME # Set by Failguard" >> /etc/hosts 
    echo "# Failguard Main Cluster Host - FGMH" >> /etc/hosts
    echo "$PRIMARY_IP $PRIMARY_NAME # Set by Failguard" >> /etc/hosts
    echo "# Failguard Standby Cluster Hosts - FGSH" >> /etc/hosts
    echo "$STANDBY_IP $STANDBY_NAME # Set by Failguard" >> /etc/hosts
    echo "# Failguard Backup Host - FGBH" >> /etc/hosts
    echo "$BACKUP_IP $BACKUP_NAME # Set by Failguard" >> /etc/hosts
    # Iterate over multiple standby's
}

create_pgbackrest_config()
{
    OWNER=$1
    sudo chmod 755 /usr/bin/pgbackrest # Moved from the install_pgbackrest function
    # Create pgBackRest configuration file and directories
    sudo mkdir -p -m 770 /var/log/pgbackrest
    sudo chown $OWNER:$OWNER /var/log/pgbackrest
    sudo mkdir -p /etc/pgbackrest
    sudo mkdir -p /etc/pgbackrest/conf.d

    sudo touch /etc/pgbackrest/pgbackrest.conf
    sudo chmod 640 /etc/pgbackrest/pgbackrest.conf
    sudo chown $OWNER:$OWNER /etc/pgbackrest/pgbackrest.conf
} 

create_pgbackrest_repository()
{
    OWNER=$1
    # Create the pgBackRest repository
    sudo mkdir -p /var/lib/pgbackrest
    sudo chmod 750 /var/lib/pgbackrest
    sudo chown $OWNER:$OWNER /var/lib/pgbackrest
}