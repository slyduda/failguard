
restart_cluster()
{
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME restart # Specified cluster does not exist
}

stop_and_restore_cluster()
{
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME stop
    sudo -u postgres pgbackrest --stanza=$CLUSTER_NAME --delta --type=standby restore
}

start_cluster()
{    
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME start
}

reload_cluser() {
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME reload
}

backup_cluster()
{
    # Can only be achieved from the backup (pgbackrest account)
    CLUSTER_NAME=$1
    sudo -u pgbackrest pgbackrest --stanza=$CLUSTER_NAME --log-level-console=detail backup
}

create_ssh_keys()
{
    USER=$1
    HOME_PATH=$(getent passwd $USER | cut -d: -f6)
    sudo -u $USER mkdir -m 750 -p $HOME_PATH/.ssh
    sudo -u $USER ssh-keygen -f $HOME_PATH/.ssh/id_rsa -t rsa -b 4096 -N ""
}

fix_ssh_permission()
{
    USER=$1
    HOME_PATH=$(getent passwd $USER | cut -d: -f6)
    sudo -u $USER mkdir -m 700 -p $HOME_PATH/.ssh
}

send_pgbackrest_public_key()
{
    HOST=$1
    # Copy public key
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        sudo ssh root@$HOST cat /var/lib/postgresql/.ssh/id_rsa.pub) | \
        sudo -u pgbackrest tee -a /home/pgbackrest/.ssh/authorized_keys

    # Test connection
    sudo -u pgbackrest ssh -q postgres@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $HOST failed."
        exit
    else
        echo "Connection to $HOST was successful."
    fi
}


send_postgres_public_key()
{
    HOST=$1
    # Copy public key
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        sudo ssh root@$HOST cat /home/pgbackrest/.ssh/id_rsa.pub) | \
        sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys


    # Test connection
    sudo -u postgres ssh -q pgbackrest@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $HOST failed."
        exit
    else
        echo "Connection to $HOST was successful."
    fi
}

send_manager_public_key()
{
    HOST=$1
    USER=$2
    # Copy public key
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        sudo ssh root@$HOST cat /root/.ssh/id_rsa.pub) | \
        HOME_PATH=$(getent passwd $USER | cut -d: -f6) | \
        tee -a $HOME_PATH/.ssh/authorized_keys


    # Test connection
    ssh -q $USER@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $HOST failed."
        exit
    else
        echo "Connection to $HOST was successful."
    fi
}