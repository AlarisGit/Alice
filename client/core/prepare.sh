#!/bin/bash

set -v
set -e

HOME=/home/alice
INSTALL_DIR=/usr/lib/alice
PYTHON_MAJOR_VERSION=3.10
PYTHON_MINOR_VERSION=9
PYTHON_VERSION=$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION
PYTHON_HOME=$INSTALL_DIR/python
PYTHON_LIB_DIR=$PYTHON_HOME/lib
LIB_DIR=$INSTALL_DIR

INSTALL_SCRIPT_DIR=`pwd`
JAVA_ENV=$HOME/java.env
ENV=$HOME/alice.env


: '
sudo yum install -y mc make gcc gcc-c++ wget zlib zlib-devel libffi-devel maven perl openssl java

cd $HOME

SSL_SOURCE_DIR=openssl-1.1.1q
FILE=$SSL_SOURCE_DIR.tar.gz
if ! [[ -s $FILE ]] ; then
  wget https://www.openssl.org/source/$FILE
fi
rm -rf $SSL_SOURCE_DIR
tar -xzf $FILE
cd $SSL_SOURCE_DIR
./config
#OPENSSL_BASE=/usr/local
#OPENSSL_HOME=$OPENSSL_BASE/openssl
# --prefix=$OPENSSL_HOME --openssldir=$OPENSSL_HOME/ssl
make
sudo rm -rf $OPENSSL_HOME
make install
#cd ..
#sudo mv openssl-1.1.1q $OPENSSL_HOME
#cd $OPENSSL_HOME
#sudo make install


#export LD_LIBRARY_PATH=$OPENSSL_HOME/lib:$LIB_DIR
'


ME=`whoami`
sudo mkdir -p $INSTALL_DIR
sudo chown -R $ME $INSTALL_DIR

cd $HOME
rm -rf Python-$PYTHON_VERSION

rm -rf $PYTHON_HOME
mkdir -p $PYTHON_HOME

FILE=Python-$PYTHON_VERSION.tgz
if ! [[ -s $FILE ]] ; then
  wget https://www.python.org/ftp/python/$PYTHON_VERSION/$FILE
fi
tar -xzf $FILE

cd Python-$PYTHON_VERSION
find . -type d | xargs chmod 0755
#./configure --prefix=$PYTHON_HOME --enable-optimizations --with-openssl=$OPENSSL_BASE --with-openssl-rpath=auto --enable-shared
./configure --prefix=$PYTHON_HOME --enable-optimizations --enable-shared
make


#grep -v -i python $PROFILE > ${PROFILE}.backup
#cat ${PROFILE}.backup > $PROFILE
echo "export PATH=$PYTHON_HOME/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin" > $ENV
echo "export PYTHONPATH=$LIB_DIR" >> $ENV
echo "export PYTHONPATH=$LIB_DIR" > $JAVA_ENV
echo "export LD_LIBRARY_PATH=$LIB_DIR:$PYTHON_LIB_DIR" >> $ENV
echo "export LD_LIBRARY_PATH=$LIB_DIR:$PYTHON_LIB_DIR" >> $JAVA_ENV
echo "export LD_PRELOAD=$PYTHON_LIB_DIR/libpython$PYTHON_MAJOR_VERSION.so.1.0" >> $JAVA_ENV


source $ENV

env

make install

echo $INSTALL_SCRIPT_DIR

cd $INSTALL_SCRIPT_DIR

python$PYTHON_MAJOR_VERSION -m pip install --upgrade pip
python$PYTHON_MAJOR_VERSION -m pip install wheel
python$PYTHON_MAJOR_VERSION -m pip install ordered-set
python$PYTHON_MAJOR_VERSION -m pip install nuitka
python$PYTHON_MAJOR_VERSION -m pip install requests


mkdir -p $LIB_DIR
rm -f $LIB_DIR/libalice*.so*


python$PYTHON_MAJOR_VERSION -m nuitka --module src/libalice2.py --include-package=requests --include-package=ssl --include-package=urllib3 --include-package=json
rm -rf libalice2.build libalice2.pyi
chmod 755 libalice2.cpython*.so
mv -f libalice2.cpython*.so $LIB_DIR/libalice2.so

gcc -g -shared -pthread -fPIC -fwrapv -O2 -L$LIB_DIR -Wl,--strip-all -Wall -fno-strict-aliasing -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION src/embed.c -o $LIB_DIR/libalice.so

gcc -g -fPIC -fwrapv -O2 -Wall -L$PYTHON_LIB_DIR -lpython$PYTHON_MAJOR_VERSION -L$LIB_DIR -lalice -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION test/test.c -o test.x

