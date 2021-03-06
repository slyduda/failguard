#!/bin/sh

install_postgres()
{
    # Install dependencies
    sudo apt install -qq -y postgresql postgresql-contrib 
}

setup_postgres()
{

    db_name=$1
    postgres_password=$2
    cluster_name=$3

    # Creates the database and changes the superuser password
    sudo -i -u postgres psql -c "ALTER USER postgres PASSWORD '$postgres_password';"  # could not change directory to "/root": Permission denied
    sudo -i -u postgres psql -c "CREATE DATABASE $db_name;" # could not change directory to "/root": Permission denied
    
    # Allow access to postgres
    ufw allow 5432

    # Configure listen addresses to make the DB available to all hosts
    sed -i "s/.*listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/$cluster_name/postgresql.conf
    sed -i "s/.*log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/$cluster_name/postgresql.conf

    # Configure the postgres to listen to all ports (We can change this later if we want)
    
    sed -i '/# IPv4 local connections:/{n;d}' /etc/postgresql/12/$cluster_name/pg_hba.conf
    sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    all             all             0.0.0.0\/0               md5/g' /etc/postgresql/12/$cluster_name/pg_hba.conf
    sed -i '/# IPv6 local connections:/{n;d}' /etc/postgresql/12/$cluster_name/pg_hba.conf
    sed -i 's/# IPv6 local connections:/# IPv6 local connections:\nhost    all             all             ::0\/0                   md5/g' /etc/postgresql/12/$cluster_name/pg_hba.conf
}