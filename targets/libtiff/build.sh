#!/bin/bash

##
# Pre-requirements:
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env CC, CXX, FLAGS, LIBS, etc...
##

if [ ! -d "$TARGET/repo" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

WORK="$TARGET/work"
mkdir -p "$WORK"
mkdir -p "$WORK/lib" "$WORK/include"

# build zlib
pushd "$TARGET/zlib"
./configure --static --prefix="$WORK"
make -j$(nproc) clean
make -j$(nproc) CFLAGS="$CFLAGS -fPIC"
make install
popd

# Build libjpeg-turbo
pushd "$TARGET/libjpeg-turbo"
cmake . -DCMAKE_INSTALL_PREFIX=$WORK -DENABLE_STATIC=on -DENABLE_SHARED=off
make -j$(nproc) clean
make -j$(nproc)
make install
popd

# Build libjbig
pushd "$TARGET/jbigkit"
make clean
make lib

mv "$TARGET"/jbigkit/libjbig/*.a "$WORK/lib/"
mv "$TARGET"/jbigkit/libjbig/*.h "$WORK/include/"
popd

cd "$TARGET/repo"
./autogen.sh
./configure --disable-shared --prefix="$WORK"
make -j$(nproc) clean
make -j$(nproc)
make install

cp "$WORK/bin/tiffcp" "$OUT/"
$CXX $CXXFLAGS -std=c++11 -I$WORK/include \
    contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc -o $OUT/tiff_read_rgba_fuzzer \
    $WORK/lib/libtiffxx.a $WORK/lib/libtiff.a $WORK/lib/libz.a $WORK/lib/libjpeg.a \
    $WORK/lib/libjbig.a $WORK/lib/libjbig85.a -Wl,-Bstatic -llzma -Wl,-Bdynamic \
    $LDFLAGS $LIBS
