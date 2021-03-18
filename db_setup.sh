#!/bin/sh

configure_database_server()
{

    DB_NAME=$1
    POSTGRES_PASSWORD=$2

    # Install dependencies
    sudo apt install postgresql postgresql-contrib

    # Creates the database and changes the superuser password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" 
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"

    # Allow access to postgres
    ufw allow 5432

        # Configure listen addresses to make the DB available to all hosts
    sed -i "s/#listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
    sed -i "s/#log_line_prefix.*/log_line_prefix = ''/g" /etc/postgresql/12/main/postgresql.conf

    # Configure the postgres to listen to all ports (We can change this later if we want)
    echo 'host    all             all             0.0.0.0/0               md5
    host    all             all             ::0/0                   md5' >> /etc/postgresql/12/main/pg_hba.conf
}