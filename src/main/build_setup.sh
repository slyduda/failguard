#!/bin/sh

build_pgbackrest() {
    mkdir /build
    wget -q -O - \
        https://github.com/pgbackrest/pgbackrest/archive/release/2.32.tar.gz | \
        tar zx -C /build
    sudo apt-get install make gcc libpq-dev libssl-dev libxml2-dev pkg-config \
       liblz4-dev libzstd-dev libbz2-dev libz-dev
    cd /build/pgbackrest-release-2.32/src && ./configure && make

    # Update and upgrade all packages on the server
    sudo apt-get install postgresql-client libxml2 install -y
}

build_droplet()
{
    NEW_HOST_NAME=$1
    new_droplet=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer "${BEARER_TOKEN}"" -d '{"name":"'"${NEW_HOST_NAME}"'","region":"'"${REGION}"'","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":['"${SSH_KEY_ID}"'],"backups":false,"ipv6":true,"vpc_uuid":"'"${VPC_ID}"'"}' "https://api.digitalocean.com/v2/droplets")
    new_droplet_id=$(echo $new_droplet | jq -r ".droplet.id")
    echo $new_droplet_id
}

get_droplet_private_ip()
{
    new_droplet_id=$1
    new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer "${BEARER_TOKEN}"" "https://api.digitalocean.com/v2/droplets/"${new_droplet_id}"")
    new_droplet_ip=$(echo $new_droplet_details | jq -r ".droplet.networks.v4[1].ip_address // empty")

    while [ -z ${new_droplet_ip} ] ; do
        sleep 10
        new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer "${BEARER_TOKEN}"" "https://api.digitalocean.com/v2/droplets/"${new_droplet_id}"")
        new_droplet_ip=$(echo $new_droplet_details | jq -r ".droplet.networks.v4[1].ip_address // empty")
    done

    ssh-keyscan $new_droplet_ip 2>&1 | grep -v "^$" > /dev/null
    while [ $? != 0 ] ; do
        sleep 5
        ssh-keyscan $new_droplet_ip 2>&1 | grep -v "^$" > /dev/null
    done

    NEW_DROPLET_IP=$(ssh -q -A -o "StrictHostKeyChecking no" root@${new_droplet_ip} 'MANAGER_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address); echo $MANAGER_IP')
    while [ -z ${NEW_DROPLET_IP} ] ; do
        sleep 10
        NEW_DROPLET_IP=$(ssh -q -A -o "StrictHostKeyChecking no" root@${new_droplet_ip} 'MANAGER_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address); echo $MANAGER_IP')
    done
    echo $NEW_DROPLET_IP
}

get_random_id()
{
    # Create a random uuid for the standby.
    uuidSample=$(uuidgen)
    IFS='-'
    read -a strarr <<< "$uuidSample"
    UNIQUEID=${strarr[0]}
    IFS=" "
    echo $UNIQUEID
}

build_droplets()
{
    UNIQUEID=$(get_random_id)

    # Later we can do it without regions
    BACKUP_NAME="db-backup.${DOMAIN}"
    MANAGER_NAME="db-manager.$DOMAIN"
    PRIMARY_NAME="db-${DB_NAME}.${DOMAIN}"
    STANDBY_NAME="db-${DB_NAME}-${UNIQUEID}.${DOMAIN}"
    
    BACKUP_ID=0 
    MANAGER_ID=0
    PRIMARY_ID=0
    STANDBY_ID=0

    if $FAILGUARD_DEBUG; then
        # Create Droplets for all types that did not have IPs specified.
        echo "Building debug droplet instances"
        if [[ $MANAGER_IP ]]; then
            echo "Manager exists"
        else
            echo "Building $MANAGER_NAME"
            MANAGER_ID=$(build_droplet $MANAGER_NAME)
        fi
        
        # Wait for all droplets to finish building
        if [[ $MANAGER_IP ]]; then
            sleep 5
        else
            sleep 45
        fi

        # Get the IP addresses of all Droplets that were created
        if [[ $MANAGER_IP ]]; then
            echo "Manager exists"
        else
            echo "Fetching $MANAGER_NAME Private IP"
            MANAGER_IP=$(get_droplet_private_ip $MANAGER_ID)
        fi

        echo $MANAGER_NAME":" $MANAGER_IP
    else
        # Create Droplets for all types that did not have IPs specified.
        echo "Building all droplet instances"
        if [[ $BACKUP_IP ]]; then
            echo "Backup exists"
        else
            echo "Building $BACKUP_NAME"
            BACKUP_ID=$(build_droplet $BACKUP_NAME)
        fi

        if [[ $MANAGER_IP ]]; then
            echo "Manager exists"
        else
            echo "Building $MANAGER_NAME"
            MANAGER_ID=$(build_droplet $MANAGER_NAME)
        fi
        
        if [[ $PRIMARY_IP ]]; then
            echo "Primary exists"
        else
            echo "Building $PRIMARY_NAME"
            PRIMARY_ID=$(build_droplet $PRIMARY_NAME)
        fi

        if [[ $STANDBY_IP ]]; then
            echo "Standby exists"
        else
            echo "Building $STANDBY_NAME"
            STANDBY_ID=$(build_droplet $STANDBY_NAME)
        fi
        
        # Wait for all droplets to finish building
        sleep 45

        # Get the IP addresses of all Droplets that were created
        echo "Fetching all droplet instance Private IPs"
        if [[ $BACKUP_IP ]]; then
            echo "Backup exists"
        else
            echo "Fetching $BACKUP_NAME Private IP"
            BACKUP_IP=$(get_droplet_private_ip $BACKUP_ID)
        fi

        if [[ $MANAGER_IP ]]; then
            echo "Manager exists"
        else
            echo "Fetching $MANAGER_NAME Private IP"
            MANAGER_IP=$(get_droplet_private_ip $MANAGER_ID)
        fi
        
        if [[ $PRIMARY_IP ]]; then
            echo "Primary exists"
        else
            echo "Fetching $PRIMARY_NAME Private IP"
            PRIMARY_IP=$(get_droplet_private_ip $PRIMARY_ID)
        fi

        if [[ $STANDBY_IP ]]; then
            echo "Standby exists"
        else
            echo "Fetching $STANDBY_NAME Private IP"
            STANDBY_IP=$(get_droplet_private_ip $STANDBY_ID)
        fi

        echo $BACKUP_NAME":" $BACKUP_IP
        echo $MANAGER_NAME":" $MANAGER_IP
        echo $PRIMARY_NAME":" $PRIMARY_IP
        echo $STANDBY_NAME":" $STANDBY_IP
    fi
}

install_pgbackrest()
{
    REMOTE_HOST=$1
    scp -o "ForwardAgent yes" /build/pgbackrest-release-2.32/src/pgbackrest $REMOTE_HOST:/usr/bin
}

self_destruct()
{
    echo "$CLUSTER_NAME has been created! This server will now self-destruct."
    # Get the Private IP of the current machine (BUILD)
    # BUILD_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
}