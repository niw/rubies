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

# Source directory we're using, default is parent of the working directory.
if [ -z "$SRCDIR" ]; then
  SRCDIR=../
fi
if [ ! -f "$SRCDIR/configure" ]; then
  echo "No configure, please run autoconf or make sure SRCDIR: $SRCDIR"
  exit 1
fi

if [ ! -z "$1" ]; then
  PREFIX="ruby-$1"
elif [ -f "$SRCDIR/version.h" ]; then
  RUBY_VERSION=`sed -n 's/^#define RUBY_VERSION "\(.*\)"/\1/p' "$SRCDIR/version.h"`
  RUBY_PATCHLEVEL=`sed -n 's/^#define RUBY_PATCHLEVEL \([-0-9]*\)/\1/p' "$SRCDIR/version.h"`
  if [ "$RUBY_PATCHLEVEL" = "-1" ]; then
    RUBY_PATCHLEVEL="dev"
  else
    RUBY_PATCHLEVEL="p$RUBY_PATCHLEVEL"
  fi
  PREFIX="ruby-$RUBY_VERSION-$RUBY_PATCHLEVEL"
fi

echo "Using $SRCDIR"
echo "  CC: $CC"
echo "  CXX: $CXX"
echo "  Prefix: $PREFIX"

# Use OS X default libraries except readline.
# I've made readline5 formura for Homebrew, because Homebrew doesn't have it.
$SRCDIR/configure \
  --prefix "$HOME/.rubies/$PREFIX" \
  --disable-option-checking \
  --enable-shared \
  --disable-install-doc \
  --with-zlib-dir=/usr/lib \
  --with-ncurses-dir=/usr/lib \
  --with-readline-dir=`brew --prefix readline5` \
  --with-libyaml-dir=`brew --prefix libyaml` \
  --with-iconv-dir=/usr/lib \
  --with-openssl-dir=/usr/lib \
  --with-arch=x86_64 \
  | tee config.log
