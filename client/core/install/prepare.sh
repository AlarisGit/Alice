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

sudo yum-config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL9/codeready/builder/aarch64/
#sudo yum config-manager --enable ol9_developer_EPEL
sudo yum install epel-release
#sudo yum install -y autoconf2.7 automake libtool
sudo yum install -y mc make gcc gcc-c++ wget zlib zlib-devel libffi-devel maven perl openssl openssl-devel java
#sudo yum --enablerepo=ol8_codeready_builder install glibc-static



cd $HOME

: '

OPENSSL_BASE=$INSTALL_DIR
OPENSSL_HOME=$OPENSSL_BASE/openssl
OPENSSL_DIR=$OPENSSL_BASE/ssl
SSL_SOURCE_DIR=openssl-1.1.1q
FILE=$SSL_SOURCE_DIR.tar.gz

cd $HOME

if ! [[ -s $FILE ]] ; then
  wget https://www.openssl.org/source/$FILE
fi
rm -rf $SSL_SOURCE_DIR
tar -xzf $FILE
cd $SSL_SOURCE_DIR
./config --prefix=$OPENSSL_HOME --openssldir=$OPENSSL_HOME/ssl

# --prefix=$OPENSSL_HOME --openssldir=$OPENSSL_HOME/ssl
make
sudo rm -rf $OPENSSL_HOME
make install
#cd ..
#sudo mv openssl-1.1.1q $OPENSSL_HOME
#cd $OPENSSL_HOME
#sudo make install

'

#LIBS="$LIBS $OPENSSL_LIBS" => LIBS="$OPENSSL_LIBS $LIBS"
#./configure --prefix="/usr/lib/alice/spython" LDFLAGS="-Wl,--no-export-dynamic -static-libgcc -static -L /usr/lib64:/usr/lib:/lib64:/lib" CPPFLAGS="-static -fPIC" LINKFORSHARED=" " DYNLOADFILE="dynload_stub.o" --disable-shared --with-libs="-ldl" --with-openssl=/usr/local --with-openssl-rpath=auto --enable-optimizations

#https://www.zlib.net/zlib-1.2.13.tar.gz

#https://github.com/libffi/libffi/archive/refs/heads/master.zip

#export LD_LIBRARY_PATH=$OPENSSL_HOME/lib:$LIB_DIR



ME=`whoami`
sudo mkdir -p $INSTALL_DIR
sudo chown -R $ME $INSTALL_DIR

cd $HOME

: '
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

'
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


cd Python-$PYTHON_VERSION

make install

echo $INSTALL_SCRIPT_DIR

cd $INSTALL_SCRIPT_DIR

python$PYTHON_MAJOR_VERSION -m pip install --upgrade pip
python$PYTHON_MAJOR_VERSION -m pip install wheel
python$PYTHON_MAJOR_VERSION -m pip install ordered-set
python$PYTHON_MAJOR_VERSION -m pip install nuitka
python$PYTHON_MAJOR_VERSION -m pip install requests
python$PYTHON_MAJOR_VERSION -m pip install cython


mkdir -p $LIB_DIR
rm -f $LIB_DIR/libalice*.so*


python$PYTHON_MAJOR_VERSION -m nuitka --module src/libalice2.py --include-package=requests --include-package=ssl --include-package=urllib3 --include-package=json
rm -rf libalice2.build libalice2.pyi
chmod 755 libalice2.cpython*.so
mv -f libalice2.cpython*.so $LIB_DIR/libalice2.so

gcc -g -shared -pthread -fPIC -fwrapv -O2 -L$LIB_DIR -Wl,--strip-all -Wall -fno-strict-aliasing -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION src/embed.c -o $LIB_DIR/libalice.so

gcc -g -fPIC -fwrapv -O2 -Wall -L$PYTHON_LIB_DIR -lpython$PYTHON_MAJOR_VERSION -L$LIB_DIR -lalice -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION test/test.c -o test.x

