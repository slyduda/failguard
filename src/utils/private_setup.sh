#!/bin/sh
# -------------------------- #
#   Private Droplet Config   #
# -------------------------- #

# Initial tools for setup
configure_private_droplet()
{
    privateGatewayIp=$1
    apt install net-tools -qq -y
    route -n

    # Add gateway IP to the private routing endpoint.
    gatewayIp=$(route -n | sed -n '3p' | awk '{ print $2 }')
    ip route add 169.254.169.254 via $gatewayIp dev eth0

    echo "What is the Private IP of this Droplet?"
    privateIp=$(curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    ip route change default via $privateIp

    # IF MOVING THE FOLLOWING WATCH OUT FOR SPACING
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
}