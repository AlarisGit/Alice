#!/bin/bash

set -v
set -e

source install.env

source $ENV

rm -f $LIB_DIR/libalice*.so*

cd ..
python$PYTHON_MAJOR_VERSION -m nuitka --module src/libalice2.py --include-package=requests --include-package=ssl --include-package=urllib3 --include-package=json
rm -rf libalice2.build libalice2.pyi
chmod 755 libalice2.cpython*.so
mv -f libalice2.cpython*.so $LIB_DIR/libalice2.so

gcc -g -shared -pthread -fPIC -fwrapv -O2 -L$LIB_DIR -Wl,--strip-all -Wall -fno-strict-aliasing -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION src/embed.c -o $LIB_DIR/libalice.so

gcc -g -fPIC -fwrapv -O2 -Wall -L$PYTHON_LIB_DIR -lpython$PYTHON_MAJOR_VERSION -L$LIB_DIR -lalice -I$PYTHON_HOME/include/python$PYTHON_MAJOR_VERSION test/test.c -o test.x

