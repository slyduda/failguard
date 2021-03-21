
restart_cluster(){
    CLUSTER_NAME=$1
    sudo pg_ctlcluster 12 $CLUSTER_NAME restart # Specified cluster does not exist
}

create_ssh_keys()
{
    USER=$1
    HOME_PATH=$(getent passwd $USER | cut -d: -f6)
    sudo -u $USER mkdir -m 750 -p $HOME_PATH/.ssh
    sudo -u $USER ssh-keygen -f $HOME_PATH/.ssh/id_rsa -t rsa -b 4096 -N ""
}

send_pgbackrest_public_key()
{
    HOST=$1
    # Copy pg-primary public key to pg-backup
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        sudo ssh root@$HOST cat /var/lib/postgresql/.ssh/id_rsa.pub) | \
        sudo -u pgbackrest tee -a /home/pgbackrest/.ssh/authorized_keys

    # Test connection from pg-backup to pg-primary
    sudo -u pgbackrest ssh -q postgres@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $HOST failed."
        exit
    else
        echo "Connection to $HOST was successful."
}


send_postgres_public_key()
{
    HOST=$1
    # Copy repository public key to pg-primary
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        sudo ssh root@$HOST cat /home/pgbackrest/.ssh/id_rsa.pub) | \
        sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys


    # Test connection from pg-primary to pg-backup
    sudo -u postgres ssh -q pgbackrest@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $HOST failed."
        exit
    else
        echo "Connection to $HOST was successful."
}