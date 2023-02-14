#!/bin/bash

set -v
set -e

source install.env

sudo yum-config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL9/codeready/builder/aarch64/
sudo yum install epel-release
sudo yum install -y mc git make gcc gcc-c++ wget zlib zlib-devel libffi-devel maven perl java glibc-static
