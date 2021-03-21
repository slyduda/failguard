#!/bin/sh

build_pgbackrest() {
    mkdir /build
    wget -q -O - \
        https://github.com/pgbackrest/pgbackrest/archive/release/2.32.tar.gz | \
        tar zx -C /build
    sudo apt-get install make gcc libpq-dev libssl-dev libxml2-dev pkg-config \
       liblz4-dev libzstd-dev libbz2-dev libz-dev
    cd /build/pgbackrest-release-2.32/src && ./configure && make

    sudo apt-get install postgresql-client libxml2

    # Update and upgrade all packages on the server
    sudo apt-get update -qq -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -qq -y
}

build_droplets()
{
    # Get the Private IP of the current machine (BUILD)
    BUILD_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)

    # Create a random uuid for the standby.
    uuidSample=$(uuidgen)
    IFS='-'
    read -a strarr <<< "$uuidSample"
    UNIQUEID=${strarr[0]}

    # Later we can do it without regions
    MANAGER_NAME="db-manager.$DOMAIN"
    PRIMARY_NAME="${DB_NAME}-db.${DOMAIN}" 
    BACKUP_NAME="db-backup.${DOMAIN}"
    STANDBY_NAME="${DB_NAME}-db-${UNIQUEID}.${DOMAIN}"

    #curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" -d '{"names":"[${MANAGER_NAME}, ${BACKUP_NAME}, ${PRIMARY_NAME}, ${STANDBY_NAME}]","region":"${REGION}","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":[${KEY_ID}],"backups":false,"ipv6":true,"vpc_uuid":"${VPC_ID}"}' "https://api.digitalocean.com/v2/droplets" | jq '(.droplets | .[] | .name, .id)'


    # MANAGER INSTANCE
    new_droplet=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" -d '{"name":"${MANAGER_NAME}","region":"${REGION}","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":[${KEY_ID}],"backups":false,"ipv6":true,"vpc_uuid":"${VPC_ID}"}' "https://api.digitalocean.com/v2/droplets")
    new_droplet_id=$(echo $new_droplet | jq .droplet.id)
    new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
    new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)

    while [ -z ${new_droplet_ip} ] ; do
        sleep 10
        new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
        new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)
    done

    MANAGER_IP=${new_droplet_ip}

    ssh root@MANAGER_IP <<"END"
MANAGER_IP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
done
END

    exit

    # PRIMARY INSTANCE
    new_droplet=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" -d '{"name":"${PRIMARY_NAME}","region":"${REGION}","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":[${KEY_ID}],"backups":false,"ipv6":true,"vpc_uuid":"${VPC_ID}"}' "https://api.digitalocean.com/v2/droplets")
    new_droplet_id=$(echo $new_droplet | jq .droplet.id)
    new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
    new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)

    while [ -z ${new_droplet_ip} ] ; do
        sleep 10
        new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
        new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)
    done

    PRIMARY_IP=${new_droplet_ip}


    # BACKUP INSTANCE
    new_droplet=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" -d '{"name":"${BACKUP_NAME}","region":"${REGION}","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":[${KEY_ID}],"backups":false,"ipv6":true,"vpc_uuid":"${VPC_ID}"}' "https://api.digitalocean.com/v2/droplets")
    new_droplet_id=$(echo $new_droplet | jq .droplet.id)
    new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
    new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)

    while [ -z ${new_droplet_ip} ] ; do
        sleep 10
        new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
        new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)
    done

    BACKUP_IP=${new_droplet_ip}


    # STANDBY INSTANCE
    new_droplet=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" -d '{"name":"${STANDBY_NAME}","region":"${REGION}","size":"s-1vcpu-1gb","image":"ubuntu-20-04-x64","ssh_keys":[${KEY_ID}],"backups":false,"ipv6":true,"vpc_uuid":"${VPC_ID}"}' "https://api.digitalocean.com/v2/droplets")
    new_droplet_id=$(echo $new_droplet | jq .droplet.id)
    new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
    new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)

    while [ -z ${new_droplet_ip} ] ; do
        sleep 10
        new_droplet_details=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${BEARER_TOKEN}" "https://api.digitalocean.com/v2/droplets/${new_droplet_id}")
        new_droplet_ip=$(echo $new_droplet_details | jq .droplet.networks.v4[].ip_address)
    done

    STANDBY_IP=${new_droplet_ip}


    # Get the private IP addresses of each
    # ------------------------------------------------------------------------ #

    # SSH into Manager 
    # PRIVATE_IP_MANAGER=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    # Exit

    # SSH into Backup 
    # PRIVATE_IP_BACKUP=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    # Exit

    # SSH into Primary 
    # PRIVATE_IP_PRIMARY=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    # Exit

    # SSH into Standby 
    # PRIVATE_IP_STANDBY=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    # Exit
}