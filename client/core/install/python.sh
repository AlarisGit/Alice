#!/bin/bash

set -v
set -e

source install.env

ME=`whoami`
sudo mkdir -p $INSTALL_DIR
sudo chown -R $ME $INSTALL_DIR



rm -rf $PYTHON_HOME
mkdir -p $PYTHON_HOME


cd $HOME

if ! [[ -s $ZLIB_FILE ]] ; then
  wget https://www.zlib.net/$ZLIB_FILE
fi
rm -rf $ZLIB_SOURCE_DIR
tar -xzf $ZLIB_FILE
cd $ZLIB_SOURCE_DIR
./configure --prefix=$PYTHON_HOME --libdir=$PYTHON_LIB_DIR --static
make 2>&1 | tee make.log
make install 2>&1 | tee -a make.log

cd $HOME


if ! [[ -s Python-$PYTHON_VERSION/Modules/Setup ]] ; then
  rm -rf Python-$PYTHON_VERSION

  if ! [[ -s $PYTHON_FILE ]] ; then
    wget https://www.python.org/ftp/python/$PYTHON_VERSION/$PYTHON_FILE
  fi
  tar -xzf $PYTHON_FILE
fi

cd Python-$PYTHON_VERSION
find . -type d | xargs chmod 0755
sed -i 's/LIBS="$LIBS $OPENSSL_LIBS"/LIBS="$OPENSSL_LIBS $LIBS"/' configure


#./configure --prefix=$PYTHON_HOME --enable-optimizations --with-openssl=$OPENSSL_BASE --with-openssl-rpath=auto --enable-shared
#./configure --prefix=$PYTHON_HOME --enable-optimizations --enable-shared


#export PY_UNSUPPORTED_OPENSSL_BUILD=static

#make clean || echo "No need to make clen"

./configure --prefix=$PYTHON_HOME LDFLAGS="-Wl,--no-export-dynamic -static-libgcc -static -L /usr/lib/alice/openssl/lib:/usr/lib/alice:/usr/lib64:/usr/lib:/lib64:/lib" CPPFLAGS="-static -fPIC" CFLAGS="-static -fPIC" LINKFORSHARED=" " DYNLOADFILE="dynload_stub.o" --disable-shared --with-libs="-ldl" --with-openssl=$OPENSSL_HOME --with-openssl-rpath=auto --enable-optimizations 2>&1 | tee -a $LOG_FILE
#./configure --prefix=$PYTHON_HOME --with-openssl=$OPENSSL_HOME --with-openssl-rpath=auto --enable-optimizations --enable-shared


openssl_path_lines=`grep OPENSSL\= Makefile | wc -l`
echo $openssl_path_lines
if [ "$openssl_path_lines" -eq "0" ]; then
  regexp="s|OPENSSL_INCLUDES\=|OPENSSL=${OPENSSL_HOME}\nOPENSSL_INCLUDES=|"
  echo "$regexp"
  sed -i "$regexp" Makefile
fi

make 2>&1 | tee -a $LOG_FILE

source $ENV | tee -a $LOG_FILE

make install 2>&1 | tee -a $LOG_FILE

python$PYTHON_MAJOR_VERSION -m pip install --upgrade pip 2>&1 | tee -a $LOG_FILE
python$PYTHON_MAJOR_VERSION -m pip install wheel 2>&1 | tee -a $LOG_FILE
python$PYTHON_MAJOR_VERSION -m pip install ordered-set 2>&1 | tee -a $LOG_FILE
python$PYTHON_MAJOR_VERSION -m pip install nuitka 2>&1 | tee -a $LOG_FILE
python$PYTHON_MAJOR_VERSION -m pip install requests 2>&1 | tee -a $LOG_FILE
python$PYTHON_MAJOR_VERSION -m pip install cython 2>&1 | tee -a $LOG_FILE
