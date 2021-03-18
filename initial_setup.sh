#!/bin/sh
# -------------------------- #
# ------ Initial Setup ----- #
# -------------------------- #

configure_server()
{
    # Update and upgrade all packages on the server
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

    USERNAME=$1
    PASSWORD=$2

    add_a_user()
    {
        if [ $(id -u) -eq 0 ]; then
            egrep "^$USERNAME" /etc/passwd >/dev/null
            if [ $? -eq 0 ]; then
                echo "$USERNAME exists!"
                exit 1
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
                useradd -m -p "$pass" "$USERNAME"
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            fi
        else
            echo "Only root may add a user to the system."
            exit 2
        fi
    }

    # Create a new user for security purposes.
    add_a_user $USERNAME $PASSWORD

    # Give the user sudo permissions
    usermod -aG sudo $USERNAME

    # Configure Firewall for security
    ufw allow ssh
    ufw enable

    # Allow the server to be accessible via password if one exists
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    service ssh restart
}