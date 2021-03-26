#!/bin/sh
source $(dirname "$0")/main/test_tools.sh

read -p "Enter a username : " USERNAME
read -s -p "Enter password : " NEW_PASSWORD
MANAGER_IP=10.124.0.12

init_something()
{
    echo "Tryinh something new"
    ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} \
        "USERNAME=$USERNAME; NEW_PASSWORD=$NEW_PASSWORD; $(< $(dirname "$0")/main/test_main.sh); $(< $(dirname "$0")/utils/test_utils.sh); $(< $(dirname "$0")/test_child.sh);"
}

init_something
