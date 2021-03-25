#!/bin/sh
source $(dirname "$0")/main/test_tools.sh

PASSWORD=password
SOME_VARIABLE=someg
MANAGER_IP=10.124.0.12

init_something()
{
    echo "Tryinh something new"
    ssh -q -A -o "StrictHostKeyChecking no" root@${MANAGER_IP} \
        "SOME_VARIABLE=$SOME_VARIABLE; PASSWORD=$PASSWORD; $(< $(dirname "$0")/main/test_main.sh); $(< $(dirname "$0")/utils/test_utils.sh); $(< $(dirname "$0")/test_child.sh);"
}

init_something
