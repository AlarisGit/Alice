#!/bin/bash

set -v
set -e

source install.env


ME=`whoami`
sudo mkdir -p $INSTALL_DIR
sudo chown -R $ME $INSTALL_DIR

cd $HOME


rm -rf $PYTHON_HOME
mkdir -p $PYTHON_HOME


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

make clean

./configure --prefix=$PYTHON_HOME LDFLAGS="-Wl,--no-export-dynamic -static-libgcc -static -L /usr/lib/alice/openssl/lib:/usr/lib64:/usr/lib:/lib64:/lib" CPPFLAGS="-static -fPIC" CFLAGS="-static -fPIC" LINKFORSHARED=" " DYNLOADFILE="dynload_stub.o" --disable-shared --with-libs="-ldl" --with-openssl=$OPENSSL_HOME --with-openssl-rpath=auto --enable-optimizations

make 2>&1 | tee make.log

exit

: '
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

'