#!/bin/bash

set -e

# Update APT
sudo apt-get update -y

# Install APT packages
sudo apt-get install -y wget zstd
