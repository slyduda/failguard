#!/bin/sh
# By default failguard creates private database 
# servers that cannot be accessed from outside of your VPN.

# Failguard currently works with Digital Ocean to help deploy 
# primary, backup, and replica servers for a single cluster.

# In order to complete this process you will need to deploy 
# four servers at a minimum. The server types are as follows:

# $name-db - (pg-primary) - Your main database instance that 
# interacts with your applications.

# $name-standby-$id - (pg-standby-$id) - Your replica database 
# in case your main goes offline.

# db-backup - (pg-backup) - Your main backup server.

# $name-disposable - A disposable instance that will be used to 
# facilitate the installation of pgbackrest

# At a later point in time, this project will support instancing 
# multiple standby servers along with, using additional clusters 
# on the same backup server

# Ask user what their username should be
# Ask user what their password should be
