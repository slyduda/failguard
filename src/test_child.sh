#!/bin/sh
source $(dirname "$0")/main/test_main.sh
source $(dirname "$0")/main/test_tools.sh

external_function
configure_server $USERNAME "$NEW_PASSWORD"