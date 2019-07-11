#!/bin/bash
# Download and compile OpenSSL for Android, and install it directly in the Android NDK development files 
# Based on http://doc.qt.io/qt-5/opensslsupport.html
# Companion script for the Docker image a12e/docker-qt
# Aurélien Brooke - License: MIT

if [ -z "$OPENSSL_VERSION" ]; then
    echo "Please define the OPENSSL_VERSION environment variable as desired."
    exit 1
fi

if [ -z "$ANDROID_DEV" ]; then
    echo "Please define the ANDROID_DEV environment variable as desired. This is where OpenSSL will be installed."
    exit 1
fi

if [ -z "$ANDROID_NDK_ARCH" ]; then
    echo "Please define the ANDROID_NDK_ARCH environment variable as desired."
    exit 1
fi

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "Please define the ANDROID_NDK_ROOT environment variable as desired."
    exit 1
fi

set -e #quit on error

cd ~/
curl -Lo openssl-${OPENSSL_VERSION}.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar xvf openssl-${OPENSSL_VERSION}.tar.gz
rm -fv openssl-${OPENSSL_VERSION}.tar.gz
mv openssl-${OPENSSL_VERSION}/ openssl/
cd openssl/

# Needed by the OpenSSL configure script
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT
# ${ANDROID_NDK_ARCH##*-} means arch-arm => arm
# ${SDK_PLATFORM##*-} means android-21 => 21
./Configure shared zlib --prefix=${ANDROID_DEV} android-${ANDROID_NDK_ARCH##*-} -D__ANDROID_API__=${SDK_PLATFORM##*-}

make -j$(nproc) depend
make -j$(nproc) CALC_VERSIONS="SHLIB_COMPAT=; SHLIB_SOVER=" build_libs
# we didn't build the "openssl" binary (error of stdout and stderr not found when linking) so we fake the file so that the install_sw step doesn't fail
touch apps/openssl
# the following is to PREVENT the install script from creating links, instead of properly copying the .so files (what is this???)
mkdir -p ${ANDROID_DEV}/lib
echo "place-holder make target for avoiding symlinks" >> ${ANDROID_DEV}/lib/link-shared
make -j$(nproc) SHLIB_EXT=.so install_sw
rm -fv ${ANDROID_DEV}/lib/link-shared

ls -alh ${ANDROID_DEV}/lib
