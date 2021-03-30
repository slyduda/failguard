
create_cluster()
{
    CLUSTER_NAME=$1
    sudo pg_createcluster 12 $CLUSTER_NAME -p 5432
}

create_stanza()
{
    CLUSTER_NAME=$1
    sudo -u pgbackrest pgbackrest --stanza=$CLUSTER_NAME --log-level-console=info stanza-create
}

update_standby_stanza()
{
    CLUSTER_NAME=$1
    sudo -u postgres pgbackrest --stanza=$CLUSTER_NAME --delta --type=standby --log-level-console=info restore
}

restart_cluster()
{
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME restart # Specified cluster does not exist
}

stop_cluster()
{
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME stop
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
        ssh -q -A -o "StrictHostKeyChecking no" root@$HOST cat /var/lib/postgresql/.ssh/id_rsa.pub) | \
        sudo -u pgbackrest tee -a /home/pgbackrest/.ssh/authorized_keys

    # Test connection
    ( sudo -u pgbackrest ssh -q -A -o "StrictHostKeyChecking no" -q postgres@$HOST ) | exit
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
        ssh -q -A -o "StrictHostKeyChecking no" root@$HOST cat /home/pgbackrest/.ssh/id_rsa.pub) | \
        sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys

    # Test connection
    ( sudo -u postgres ssh -q -A -o "StrictHostKeyChecking no" -q pgbackrest@$HOST ) | exit
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
        root@$HOST cat /root/.ssh/id_rsa.pub) | \
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

send_public_key()
{
    HOST=$1
    SENDER=$2
    RECEIVER=$2
    SENDER_PATH=$(getent passwd $SENDER | cut -d: -f6)
    cat $SENDER_PATH/.ssh/id_rsa.pub | ssh root@$HOST 'RECEIVER_PATH=$(getent passwd $SENDER | cut -d: -f6); cat >> $RECEIVER_PATH/.ssh/authorized_keys;'

    # Test connection
    sudo -u $SENDER ssh -q $RECEIVER@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $RECEIVER@$HOST failed."
        exit
    else
        echo "Connection to $RECEIVER@$HOST was successful."
    fi
}