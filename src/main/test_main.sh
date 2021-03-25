#!/bin/sh
echo "FAKE MAIN FUNCTION"

external_function()
{
    EXTERNAL_HOSTNAME=$(hostname)
    sudo apt-get update -qq -y
    echo "Finished sudo apt-get update on: "$EXTERNAL_HOSTNAME
}