#!/bin/sh
# -------------------------- #
#  Postgres Database Setup   #
# -------------------------- #

apt install postgresql postgresql-contrib

echo "Enter your postgres (superuser) password?"
read postgresPassword

echo "Enter a database name?"
read dbname

# Creates the database and changes the superuser password
sudo -u postgres psql << EOF
ALTER USER postgres PASSWORD '$postgresPassword';
CREATE DATABASE $dbname;
EOF