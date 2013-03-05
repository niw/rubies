#!/bin/sh

# Assume the parent directory has ruby source code.
if [ -z "$SRCDIR" ]; then
  SRCDIR=../
fi
echo "Using ruby source at $SRCDIR"

# If we couldn't find configure script, then give up.
if [ ! -f "$SRCDIR/configure" ]; then
  echo "No configure script found."
  exit 1
fi

if [ ! -f "$SRCDIR/version.h" ]; then
  echo "No version.h found."
  exit 1
fi

# Read ruby version from version.h.
RUBY_VERSION=`sed -n 's/^#define RUBY_VERSION "\(.*\)"/\1/p' "$SRCDIR/version.h"`
RUBY_MAJOR_VERSION=`echo "$RUBY_VERSION"|cut -d . -f 1`
RUBY_MINOR_VERSION=`echo "$RUBY_VERSION"|cut -d . -f 2`

# Read patch level from version.h.
RUBY_PATCHLEVEL=`sed -n 's/^#define RUBY_PATCHLEVEL \([-0-9]*\)/\1/p' "$SRCDIR/version.h"`
if [ "$RUBY_PATCHLEVEL" = "-1" ]; then
  RUBY_PATCHLEVEL="dev"
else
  RUBY_PATCHLEVEL="p$RUBY_PATCHLEVEL"
fi

if [ "$RUBY_MAJOR_VERSION" = "1" ]; then
  # Use normal GCC if we have.
  # Once we install Xcode 4.2, it will replace /usr/bin/gcc to llvm-gcc
  # which causes some unexpected error.
  if [ -f /usr/bin/gcc-4.2 ]; then
    export CC=/usr/bin/gcc-4.2
  fi
  if [ -f /usr/bin/g++-4.2 ]; then
    export CXX=/usr/bin/g++-4.2
  fi
fi

# Default prefix is like ~/.rubies/ruby-2.0.0-p0
if [ ! -z "$1" ]; then
  PREFIX="ruby-$1"
else
  PREFIX="ruby-$RUBY_VERSION-$RUBY_PATCHLEVEL"
fi

# I know Ruby 2.0 is not using libiconv, though.
CONFIGURE_OPTIONS="
  --prefix $HOME/.rubies/$PREFIX \
  --disable-option-checking \
  --enable-shared \
  --disable-install-doc \
  --with-arch=x86_64 \
  --with-zlib-dir=/usr \
  --with-ncurses-dir=/usr \
  --with-iconv-dir=/usr"

check_homebrew() {
  # FIXME better way to know the cellar is installed or not.
  if `brew list "$1" 2>&1 >/dev/null`; then
    return 0
  else
    echo "No $1 found in Homebrew."
    exit 1
  fi
}

add_configure_option() {
  CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS \
    $1"
}

# I've made readline5 formura for Homebrew, because Homebrew doesn't have it.
# See https://github.com/niw/homebrew-additions
check_homebrew "readline5"
add_configure_option "--with-readline-dir=`brew --prefix readline5`"

# Ruby 2.x.x
if [ "$RUBY_MAJOR_VERSION" = "2" ]; then
  check_homebrew "openssl"
  add_configure_option "--with-openssl-dir=`brew --prefix openssl`"

  check_homebrew "libyaml"
  add_configure_option "--with-libyaml-dir=`brew --prefix libyaml`"
fi

# Ruby 1.9.x
if [ "$RUBY_MAJOR_VERSION" = "1" ]; then
  if [ "$RUBY_MINOR_VERSION" = "9" ]; then
    check_homebrew "libyaml"
    add_configure_option "--with-libyaml-dir=`brew --prefix libyaml`"
  fi
fi

echo "Using $SRCDIR"
echo "  CC: $CC"
echo "  CXX: $CXX"
echo "Options: $CONFIGURE_OPTIONS"

$SRCDIR/configure $CONFIGURE_OPTIONS \
  | tee config.log
