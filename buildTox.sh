#!/bin/bash

WINDOWS_TOOLCHAIN=i686-w64-mingw32
LIB_VPX_TARGET=x86-win32-gcc

BASEDIR="$( dirname "$0" )"

[ -z "$BASEDIR" ] && BASEDIR="$(pwd)"

if [ ! -d "$BASEDIR" ]; then
  echo "Can not find root dir"
  exit 1
fi

cd "$BASEDIR"
BASEDIR="$(pwd)"

[ ! -d ".build" ] && mkdir .build
[ -d bin ]        && rm -rf bin

mkdir bin

cd .build

for I in  https://github.com/irungentoo/toxcore http://git.chromium.org/webm/libvpx.git https://github.com/jedisct1/libsodium ; do
  CURRENT="$( basename "$I" | sed 's/\.git$//g' )"
  echo "Updating / cloning $CURRENT"
  if [ -d "$CURRENT" ]; then
    pushd "$CURRENT"
    git pull
    popd
  else
    git clone "$I"
  fi
done

[ ! -f "opus-1.1.tar.gz" ] && wget http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz

if [ ! -d "opus" ]; then
  tar -xf opus-1.1.tar.gz
  mv opus-1.1 opus
fi

for I in buildWin; do
  if [ -e "$I" ]; then
    rm -rf "$I"
  fi

  mkdir "$I"
  pushd "$I"

  for J in toxcore libvpx libsodium opus; do
    cp -r ../$J .
  done

  popd
done

export MAKEFLAGS=j$(nproc)
PREFIX_DIR="$BASEDIR/bin"

pushd buildWin
pushd libvpx

CROSS="$WINDOWS_TOOLCHAIN"- ./configure --target="$LIB_VPX_TARGET" --prefix="$PREFIX_DIR" --disable-examples --disable-unit-tests --disable-shared --enable-static
make
make install

popd
pushd opus

./autogen.sh
./configure --host="$WINDOWS_TOOLCHAIN" --prefix="$PREFIX_DIR" --disable-extra-programs --disable-doc --disable-shared --enable-static
make
make install

popd
pushd libsodium

./autogen.sh
./configure --host="$WINDOWS_TOOLCHAIN" --prefix="$PREFIX_DIR" --disable-shared --enable-static
make
make install

popd
pushd toxcore

./autogen.sh
./configure --host="$WINDOWS_TOOLCHAIN" --prefix="$PREFIX_DIR" --disable-ntox --disable-tests --disable-testing --with-dependency-search="$PREFIX_DIR" --disable-shared --enable-static
make
make install

popd
popd

rm -rf buildWin

cd "$PREFIX_DIR"
mkdir tmp
cd tmp
$WINDOWS_TOOLCHAIN-ar x ../lib/libtoxcore.a
$WINDOWS_TOOLCHAIN-ar x ../lib/libtoxav.a
$WINDOWS_TOOLCHAIN-ar x ../lib/libtoxdns.a
$WINDOWS_TOOLCHAIN-ar x ../lib/libtoxencryptsave.a
$WINDOWS_TOOLCHAIN-gcc -Wl,--export-all-symbols -Wl,--out-implib=libtox.dll.a -shared -o libtox.dll ./*.o ../lib/*.a /usr/$WINDOWS_TOOLCHAIN/lib/libwinpthread.a -liphlpapi -lws2_32 -static-libgcc

cp libtox.dll ..
cd ..

find . -maxdepth 1 -name "[a-z]*" -type d -exec rm -rf {} \;

echo "DONE"
