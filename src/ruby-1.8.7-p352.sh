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

# Use OS X default libraries except readline.
# I've made readline5 formura for Homebrew, because Homebrew doesn't have it.
../configure \
	--prefix "$HOME/.rubies/ruby-1.8.7-p352" \
	--disable-option-checking \
	--enable-shared \
	--disable-install-doc \
	--with-zlib-dir=/usr/lib \
	--with-ncurses-dir=/usr/lib \
	--with-readline-dir=`brew --prefix readline5` \
	--with-libyaml-dir=`brew --prefix libyaml` \
	--with-iconv-dir=/usr/lib \
	--with-openssl-dir=/usr/lib \
	--with-arch=x86_64
