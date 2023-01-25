set -v
HOME=/home/alice
PYTHON_MAJOR_VERSION=3.8
PYTHON_MINOR_VERSION=16
PYTHON_VERSION=$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION
PROFILE=$HOME/.bash_profile
LIBDIR=$HOME/lib

: '
sudo yum install -y mc make gcc gcc-c++ wget zlib zlib-devel libffi-devel maven

cd $HOME
wget https://www.openssl.org/source/openssl-1.1.1q.tar.gz
tar -xzf openssl-1.1.1q.tar.gz
cd openssl-1.1.1q
./config
make
cd ..
sudo mv openssl-1.1.1q /usr/local/openssl
cd /usr/local/openssl
sudo make install
cd $HOME


rm -rf $HOME/python

mkdir -p $HOME/python
cd $HOME/python
rm -f Python*.tgz
wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
tar -xzf Python-$PYTHON_VERSION.tgz
find $HOME/python -type d | xargs chmod 0755
cd Python-$PYTHON_VERSION
./configure --prefix=$HOME/python --enable-optimizations --with-openssl=/usr/local --with-openssl-rpath=auto --enable-shared
make
'

grep -v -i python $PROFILE > ${PROFILE}.backup
cat ${PROFILE}.backup > $PROFILE
echo "export PATH=$HOME/python/bin:$HOME/python/Python-$PYTHON_VERSION:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin" >> $PROFILE
echo "export PYTHONPATH=$LIBDIR:$HOME/python/Python-$PYTHON_VERSION" >> $PROFILE
echo "export LD_LIBRARY_PATH=$HOME/python/lib:$HOME/lib" >> $PROFILE

source $PROFILE
#make install

python -m pip install --upgrade pip
python -m pip install wheel
python -m pip install ordered-set
python -m pip install nuitka
python -m pip install requests

rm -f $LIBDIR/libalice*.so

mkdir -p $LIBDIR
cp -f $HOME/python/Python-$PYTHON_VERSION/libpython${PYTHON_MAJOR_VERSION}.so $LIBDIR

python$PYTHON_MAJOR_VERSION -m nuitka --module src/libalice.py --include-package=requests --include-package=ssl --include-package=urllib3 --include-package=json
rm -rf libalice.build libalice.pyi
chmod 755 libalice.cpython*.so
mv -f libalice.cpython*.so $LIBDIR/libalice.so

gcc -g -shared -pthread -fPIC -fwrapv -O2 -L$LIBDIR -Wl,--strip-all -Wall -fno-strict-aliasing -I$HOME/python/include/python$PYTHON_MAJOR_VERSION src/embed.c -o $LIBDIR/libalice2.so

gcc -g -fPIC -fwrapv -O2 -Wall -L$LIBDIR -lpython$PYTHON_MAJOR_VERSION -lpython$PYTHON_MAJOR_VERSION -lalice2 -I$HOME/python/include/python$PYTHON_MAJOR_VERSION src/test.c -o test.x

