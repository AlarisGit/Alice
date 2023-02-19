#!/bin/bash

set -v
set -e

source install.env

cd $HOME

if ! [[ -s $SSL_SOURCE_FILE ]] ; then
  wget https://www.openssl.org/source/$SSL_SOURCE_FILE
fi
rm -rf $SSL_SOURCE_DIR
tar -xzf $SSL_SOURCE_FILE
cd $SSL_SOURCE_DIR
./config --prefix=$OPENSSL_HOME --openssldir=$OPENSSL_DIR
make 2>&1 | tee make.log
rm -rf $OPENSSL_HOME
rm -rf $OPENSSL_DIR
make install 2>&1 | tee -a make.log


