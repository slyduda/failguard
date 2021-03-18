#!/bin/sh
# -------------------------- #
# ------ Initial Setup ----- #
# -------------------------- #

# Update and upgrade all packages on the server
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y


# Ask for user info
read -p "Enter username : " username
read -s -p "Enter password : " password

add_a_user()
{
    if [ $(id -u) -eq 0 ]; then
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
            echo "$username exists!"
            exit 1
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -p "$pass" "$username"
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
        fi
    else
        echo "Only root may add a user to the system."
        exit 2
    fi
}

# Create a new user for security purposes.
add_a_user $username $password

# Give the user sudo permissions
usermod -aG sudo $username

# Configure Firewall for security
ufw allow ssh
ufw allow 5432
ufw enable

# Allow the server to be accessible via password if one exists
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
service ssh restart