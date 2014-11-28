#!/bin/sh
CURRENT_DIR="$(cd $(dirname "$0"); pwd)"

# Use gcc-4.2.
# Normally, you want to install both Xcode command line tools and apple-gcc42.
# $ xcode-select --install
# $ brew install apple-gcc42
if `type gcc-4.2 2>&1 >/dev/null`; then
  export CC=`which gcc-4.2`
  export CXX=`which g++-4.2`
  # If using OS X 10.10 (or also later,) use lower version of deployment target
  # to suppress errors.
  if `type sw_vers 2>&1 >/dev/null`; then
    if [ `sw_vers -productVersion|cut -d . -f 2` -gt 9 ]; then
      export MACOSX_DEPLOYMENT_TARGET=10.9
    fi
  fi
else
  echo "No gcc-4.2 found."
  exit 1
fi

# Apply patch to avoid install rubygems and not-so-useful-gems.
patch -N -p0 < "$CURRENT_DIR/ruby-enterprise-1.8.7-2009.10-installer.rb.patch"

# Use OS X default libraries except readline.
# I've made readline5 formura for Homebrew, because Homebrew doesn't have it.
./installer \
	-a "$HOME/.rubies/ruby-enterprise-1.8.7-2009.10" \
	--dont-install-useful-gems \
	-c --disable-option-checking \
	-c --enable-shared \
	-c --disable-install-doc \
	-c --with-zlib-dir=/usr/lib \
	-c --with-ncurses-dir=/usr/lib \
	-c --with-readline-dir=`brew --prefix readline5` \
	-c --with-iconv-dir=/usr/lib \
	-c --with-openssl-dir=/usr/lib \
	-c --with-arch=x86_64
