#!/bin/sh

install_postgres()
{

    DB_NAME=$1
    POSTGRES_PASSWORD=$2

    # Install dependencies
    sudo apt install postgresql postgresql-contrib

    # Creates the database and changes the superuser password
    sudo -i -u postgres psql -c "ALTER USER postgres NEW_PASSWORD '$POSTGRES_PASSWORD';"  # could not change directory to "/root": Permission denied
    sudo -i -u postgres psql -c "CREATE DATABASE $DB_NAME;" # could not change directory to "/root": Permission denied
    
    # Allow access to postgres
    ufw allow 5432

    # Configure listen addresses to make the DB available to all hosts
    sed -i "s/.*listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
    sed -i "s/.*log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/main/postgresql.conf

    # Configure the postgres to listen to all ports (We can change this later if we want)
    
    sed -i '/# IPv4 local connections:/{n;d}' /etc/postgresql/12/main/pg_hba.conf
    sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    all             all             0.0.0.0\/0               md5/g' /etc/postgresql/12/main/pg_hba.conf
    sed -i '/# IPv6 local connections:/{n;d}' /etc/postgresql/12/main/pg_hba.conf
    sed -i 's/# IPv6 local connections:/# IPv6 local connections:\nhost    all             all             ::0\/0                   md5/g' /etc/postgresql/12/main/pg_hba.conf
}