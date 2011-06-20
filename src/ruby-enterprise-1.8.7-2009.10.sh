#!/bin/sh
CURRENT_DIR="$(cd $(dirname "$0"); pwd)"

# Select normal GCC.
# Once we install Xcode 4.2, it will replace /usr/bin/gcc to llvm-gcc
# which causes some unexpected error for now.
if [ -f /usr/bin/gcc-4.2 ]; then
	export CC=/usr/bin/gcc-4.2
fi
if [ -f /usr/bin/g++-4.2 ]; then
	export CXX=/usr/bin/g++-4.2
fi

# Apply patch to avoid install rubygems and not-so-useful-gems.
patch -N -p0 < "$CURRENT_DIR/ruby-enterprise-1.8.7-2009.10-installer.rb.patch"

# Install REE with dependencies.
# Use OS X default libraries.
./installer \
	-a "$HOME/.rubies/ruby-enterprise-1.8.7-2009.10" \
	--dont-install-useful-gems \
	-c --with-zlib-dir=/usr/lib \
	-c --with-readline-dir=/usr/lib \
	-c --with-iconv-dir=/usr/lib \
	-c --with-openssl-dir=/usr/lib
