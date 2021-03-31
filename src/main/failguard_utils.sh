
create_cluster()
{
    cluster_name=$1
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@${cluster_name}@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    sudo pg_createcluster 12 $cluster_name -p 5432
}

create_stanza()
{
    cluster_name=$1
    username=$2
    sudo -u $username pgbackrest --stanza=$cluster_name --log-level-console=info stanza-create
}

update_standby_stanza()
{
    cluster_name=$1
    sudo -u postgres pgbackrest --stanza=$cluster_name --delta --type=standby --log-level-console=info restore
}

restart_cluster()
{
    cluster_name=$1
    sudo pg_ctlcluster 12 $cluster_name restart # Specified cluster does not exist
}

stop_cluster()
{
    cluster_name=$1
    sudo pg_ctlcluster 12 $cluster_name stop
}

stop_and_restore_cluster()
{
    cluster_name=$1
    sudo pg_ctlcluster 12 $cluster_name stop
    sudo -u postgres pgbackrest --stanza=$cluster_name --delta --type=standby restore
}

start_cluster()
{    
    cluster_name=$1
    sudo pg_ctlcluster 12 $cluster_name start
}

reload_cluser() {
    cluster_name=$1
    sudo pg_ctlcluster 12 $cluster_name reload
}

backup_cluster()
{
    # Can only be achieved from the backup (pgbackrest account)
    cluster_name=$1
    sudo -u pgbackrest pgbackrest --stanza=$cluster_name --log-level-console=detail backup
}

create_ssh_keys()
{
    username=$1
    home_path=$(getent passwd $username | cut -d: -f6)
    sudo -u $username mkdir -m 750 -p $home_path/.ssh
    sudo -u $username ssh-keygen -f $home_path/.ssh/id_rsa -t rsa -b 4096 -N ""
}

fix_ssh_permission()
{
    username=$1
    home_path=$(getent passwd $username | cut -d: -f6)
    sudo -u $username mkdir -m 700 -p $home_path/.ssh
}

send_pgbackrest_public_key()
{
    host_name=$1
    # Copy public key
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        ssh -q -A -o "StrictHostKeyChecking no" root@$host_name cat /var/lib/postgresql/.ssh/id_rsa.pub) | \
        sudo -u pgbackrest tee -a /home/pgbackrest/.ssh/authorized_keys

    # Test connection
    ( sudo -u pgbackrest ssh -q -A -o "StrictHostKeyChecking no" -q postgres@$host_name ) | exit
    if [ $? -ne 0 ]; then
        echo "Connection to $host_name failed."
        exit
    else
        echo "Connection to $host_name was successful."
    fi
}


send_postgres_public_key()
{
    host_name=$1
    # Copy public key
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        ssh -q -A -o "StrictHostKeyChecking no" root@$host_name cat /home/pgbackrest/.ssh/id_rsa.pub) | \
        sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys

    # Test connection
    ( sudo -u postgres ssh -q -A -o "StrictHostKeyChecking no" -q pgbackrest@$host_name ) | exit
    if [ $? -ne 0 ]; then
        echo "Connection to $host_name failed."
        exit
    else
        echo "Connection to $host_name was successful."
    fi
}

send_manager_public_key()
{
    host_name=$1
    username=$2
    # Copy public key
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        root@$host_name cat /root/.ssh/id_rsa.pub) | \
        HOME_PATH=$(getent passwd $username | cut -d: -f6) | \
        tee -a $host_name/.ssh/authorized_keys


    # Test connection
    ssh -q $username@$host_name exit
    if [ $? -ne 0 ]; then
        echo "Connection to $host_name failed."
        exit
    else
        echo "Connection to $host_name was successful."
    fi
}

send_public_key()
{
    host_name=$1
    sender=$2
    receiver=$2
    sender_path=$(getent passwd $sender | cut -d: -f6)
    cat $sender_path/.ssh/id_rsa.pub | ssh root@$host_name 'RECEIVER_PATH=$(getent passwd $sender | cut -d: -f6); cat >> $RECEIVER_PATH/.ssh/authorized_keys;'

    # Test connection
    sudo -u $sender ssh -q $receiver@$host_name exit
    if [ $? -ne 0 ]; then
        echo "Connection to $receiver@$host_name failed."
        exit
    else
        echo "Connection to $receiver@$host_name was successful."
    fi
}