#!/bin/sh

# Select normal GCC.
# Once we install Xcode 4.2, it will replace /usr/bin/gcc to llvm-gcc
# which causes some unexpected error for now.
if [ -f /usr/bin/gcc-4.2 ]; then
	export CC=/usr/bin/gcc-4.2
fi
if [ -f /usr/bin/g++-4.2 ]; then
	export CXX=/usr/bin/g++-4.2
fi

# Use OS X default libraries.
./configure \
	--prefix "$HOME/.rubies/ruby-1.9.2-p180" \
	--with-zlib-dir=/usr/lib \
	--with-readline-dir=/usr/lib \
	--with-iconv-dir=/usr/lib \
	--with-openssl-dir=/usr/lib \
	--enable-shared \
	--enable-pthread \
	--disable-install-doc \
	--with-arch=x86_64
