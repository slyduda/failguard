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
    new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer "${BEARER_TOKEN}"" "https://api.digitalocean.com/v2/droplets/"${new_droplet_id}"")
    new_droplet_ip=$(echo $new_droplet_details | jq -r ".droplet.networks.v4[1].ip_address // empty")

    while [ -z ${new_droplet_ip} ] ; do
        sleep 10
        new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer "${BEARER_TOKEN}"" "https://api.digitalocean.com/v2/droplets/"${new_droplet_id}"")
        new_droplet_ip=$(echo $new_droplet_details | jq -r ".droplet.networks.v4[1].ip_address // empty")
    done

    sleep 30
    NEW_DROPLET_IP=$(ssh -q -A -o "StrictHostKeyChecking no" root@${new_droplet_ip} 'MANAGER_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address); echo $MANAGER_IP')
    echo $NEW_DROPLET_IP

}

build_droplets()
{
    # Create a random uuid for the standby.
    uuidSample=$(uuidgen)
    IFS='-'
    read -a strarr <<< "$uuidSample"
    UNIQUEID=${strarr[0]}
    IFS=" "

    # Later we can do it without regions
    MANAGER_NAME="db-manager.$DOMAIN"
    PRIMARY_NAME="db-${DB_NAME}.${DOMAIN}"
    BACKUP_NAME="db-backup.${DOMAIN}"
    STANDBY_NAME="db-${DB_NAME}-${UNIQUEID}.${DOMAIN}"

    # MANAGER INSTANCE
    echo "Building the manager instance"
    MANAGER_IP=$(build_droplet $MANAGER_NAME)
    echo "Manager Private IP:" $MANAGER_IP

    # PRIMARY INSTANCE
    echo "Building the primary instance"
    PRIMARY_IP=$(build_droplet $PRIMARY_NAME)
    echo "Primary Private IP:" $PRIMARY_IP

    # BACKUP INSTANCE
    echo "Building the backup instance"
    BACKUP_IP=$(build_droplet $BACKUP_NAME)
    echo "Backup Private IP:" $BACKUP_IP

    # STANDBY INSTANCE
    echo "Building the standby instance"
    STANDBY_IP=$(build_droplet $STANDBY_NAME)
    echo "Standby Private IP:" $STANDBY_IP
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