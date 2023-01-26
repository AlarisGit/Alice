set -v
HOME=/home/alice
PYTHON_MAJOR_VERSION=3.10
PYTHON_MINOR_VERSION=9
PYTHON_VERSION=$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION
PROFILE=$HOME/.bash_profile
PYTHON_HOME=$HOME/python
OPENSSL_BASE=/usr/local
OPENSSL_HOME=$OPENSSL_BASE/openssl
LIBDIR=$PYTHON_HOME/lib

INSTALL_SCRIPT_DIR=`pwd`

: '
sudo yum install -y mc make gcc gcc-c++ wget zlib zlib-devel libffi-devel maven perl

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
# --prefix=$OPENSSL_HOME --openssldir=$OPENSSL_HOME/ssl
make
sudo rm -rf $OPENSSL_HOME
make install
#cd ..
#sudo mv openssl-1.1.1q $OPENSSL_HOME
#cd $OPENSSL_HOME
#sudo make install



#export LD_LIBRARY_PATH=$OPENSSL_HOME/lib:$LIBDIR

cd $HOME
rm -rf $PYTHON_HOME
rm -rf Python-$PYTHON_VERSION
mkdir -p $PYTHON_HOME

FILE=Python-$PYTHON_VERSION.tgz
if ! [[ -s $FILE ]] ; then
  wget https://www.python.org/ftp/python/$PYTHON_VERSION/$FILE
fi
tar -xzf $FILE

cd Python-$PYTHON_VERSION
find . -type d | xargs chmod 0755
./configure --prefix=$PYTHON_HOME --enable-optimizations --with-openssl=$OPENSSL_BASE --with-openssl-rpath=auto --enable-shared
make

'

grep -v -i python $PROFILE > ${PROFILE}.backup
cat ${PROFILE}.backup > $PROFILE
echo "export PATH=$PYTHON_HOME/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin" >> $PROFILE
#echo "export PYTHONPATH=$LIBDIR:$HOME/python/Python-$PYTHON_VERSION" >> $PROFILE
echo "export PYTHONPATH=$LIBDIR" >> $PROFILE
echo "export LD_LIBRARY_PATH=$LIBDIR" >> $PROFILE
#echo "export LD_PRELOAD=$HOME/python/lib/python$PYTHON_MAJOR_VERSION.so.1.0:$LIBDIR/libalice.so:$LIBDIR/libalice2.so" >> $PROFILE

source $PROFILE

env

make install

echo $INSTALL_SCRIPT_DIR

cd $INSTALL_SCRIPT_DIR


python$PYTHON_MAJOR_VERSION -m pip install --upgrade pip
python$PYTHON_MAJOR_VERSION -m pip install wheel
python$PYTHON_MAJOR_VERSION -m pip install ordered-set
python$PYTHON_MAJOR_VERSION -m pip install nuitka
python$PYTHON_MAJOR_VERSION -m pip install requests


mkdir -p $LIBDIR
rm -f $LIBDIR/libalice*.so*


python$PYTHON_MAJOR_VERSION -m nuitka --module src/libalice.py --include-package=requests --include-package=ssl --include-package=urllib3 --include-package=json
rm -rf libalice.build libalice.pyi
chmod 755 libalice.cpython*.so
mv -f libalice.cpython*.so $LIBDIR/libalice.so

gcc -g -shared -pthread -fPIC -fwrapv -O2 -L$LIBDIR -Wl,--strip-all -Wall -fno-strict-aliasing -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION src/embed.c -o $LIBDIR/libalice2.so

gcc -g -fPIC -fwrapv -O2 -Wall -L$LIBDIR -lpython$PYTHON_MAJOR_VERSION -lalice2 -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION test/test.c -o test.x

