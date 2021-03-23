#!/bin/sh
create_manager_tables()
{
    # Create Table Clusters (ID, Name)
    sudo -i -u postgres psql -c "CREATE TABLE clusters(id serial PRIMARY KEY, name VARCHAR ( 50 ) UNIQUE NOT NULL);"
    # Create Table Servers (ID, IP, Names, Cluster_ID)
    sudo -i -u postgres psql -c "CREATE TABLE servers(id serial PRIMARY KEY, ip VARCHAR ( 16 ) UNIQUE NOT NULL, name VARCHAR ( 50 ) UNIQUE NOT NULL, type VARCHAR (1) NOT NULL); "
}

insert_failguard_server()
{
    # Insert Servers
    HOST_IP=$1
    HOST_NAME=$2
    HOST_TYPE=$3
    sudo -i -u postgres psql -c "INSERT INTO servers(ip, name, type) VALUES ($HOST_IP, $HOST_NAME, $HOST_TYPE);"    
}

insert_failguard_cluster()
{
    # Insert Cluster
    CLUSTER_NAME=$1
    sudo -i -u postgres psql -c "INSERT INTO clusters(name) VALUES ($CLUSTER_NAME);"    
}