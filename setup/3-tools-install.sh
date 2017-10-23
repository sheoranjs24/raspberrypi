#!/bin/bash
# Update the package list, update all packages and remove any packages that are no longer required
sudo apt-get update -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y

## Mail Service
sudo apt-get install postfix -y
