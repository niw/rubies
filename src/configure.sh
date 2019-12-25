#!/bin/sh

# Assume the parent directory has ruby source code.
if [[ -z "$SRCDIR" ]]; then
  SRCDIR=../
fi
echo "Using ruby source at $SRCDIR"
readonly SRCDIR

# If we couldn't find `configure` script, then give up.
if [[ ! -f "$SRCDIR/configure" ]]; then
  echo "No configure script found." >&2
  exit 1
fi

# Read ruby version from `version.h`.
if [[ ! -f "$SRCDIR/version.h" ]]; then
  echo "No version.h found." >&2
  exit 1
fi
RUBY_VERSION=$(sed -n 's/^#define RUBY_VERSION "\(.*\)"/\1/p' "$SRCDIR/version.h")
if [[ -z $RUBY_VERSION ]]; then
  # Since Ruby 2.7.0, `verison.h` no longer has a plain text `RUBY_VERSION` definition.
  # Use `include/ruby/version.h` instead.
  if [[ ! -f "$SRCDIR/include/ruby/version.h" ]]; then
    echo "No include/ruby/version.h found." >&2
    exit 1
  fi

  readonly RUBY_VERSION_MAJOR=$(sed -n 's/^#define RUBY_API_VERSION_MAJOR \(\d*\)/\1/p' "$SRCDIR/include/ruby/version.h")
  readonly RUBY_VERSION_MINOR=$(sed -n 's/^#define RUBY_API_VERSION_MINOR \(\d*\)/\1/p' "$SRCDIR/include/ruby/version.h")
  readonly RUBY_VERSION_TEENY=$(sed -n 's/^#define RUBY_VERSION_TEENY \(\d*\)/\1/p' "$SRCDIR/version.h")
  RUBY_VERSION="$RUBY_VERSION_MAJOR.$RUBY_VERSION_MINOR.$RUBY_VERSION_TEENY"
else
  readonly RUBY_VERSION_MAJOR=$(echo "$RUBY_VERSION"|cut -d . -f 1)
  readonly RUBY_VERSION_MINOR=$(echo "$RUBY_VERSION"|cut -d . -f 2)
  readonly RUBY_VERSION_TEENY=$(echo "$RUBY_VERSION"|cut -d . -f 3)
fi
readonly RUBY_VERSION

# Read patch level from `version.h`.
RUBY_PATCHLEVEL=`sed -n 's/^#define RUBY_PATCHLEVEL \([-0-9]*\)/\1/p' "$SRCDIR/version.h"`
if [ "$RUBY_PATCHLEVEL" = "-1" ]; then
  RUBY_PATCHLEVEL="dev"
else
  RUBY_PATCHLEVEL="p$RUBY_PATCHLEVEL"
fi
readonly RUBY_PATCHLEVEL

# Use gcc-4.2.
# Normally, you want to install both Xcode command line tools and apple-gcc42.
# $ xcode-select --install
# $ brew install apple-gcc42
if [[ "$RUBY_VERSION_MAJOR" = "1" && "$RUBY_VERSION_MINOR" != "9" ]]; then
  if type "gcc-4.2" 2>&1 >/dev/null; then
    export CC=$(which gcc-4.2)
    export CXX=$(which g++-4.2)
  else
    echo "No gcc-4.2 found." >&2
    exit 1
  fi
fi

# Default prefix is like `~/.rubies/ruby-2.0.0-p0`
if [[ ! -z "$1" ]]; then
  PREFIX="ruby-$1"
else
  PREFIX="ruby-$RUBY_VERSION-$RUBY_PATCHLEVEL"
fi
readonly PREFIX

# I know Ruby 2.0 is not using `libiconv`, though.
CONFIGURE_OPTIONS="
  --prefix $HOME/.rubies/$PREFIX \
  --disable-option-checking \
  --enable-shared \
  --disable-install-doc \
  --with-arch=x86_64 \
  --without-gdbm \
  --without-tcl \
  --without-tk \
  --with-iconv-dir=/usr \
  --with-ncurses-dir=/usr \
  --with-zlib-dir=/usr \
  "

check_homebrew() {
  # FIXME better way to know the cellar is installed or not.
  if brew list "$1" 2>&1 >/dev/null; then
    return 0
  else
    echo "No $1 found in Homebrew." >&2
    exit 1
  fi
}

add_configure_option() {
  CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS $1"
}

check_homebrew "readline"
add_configure_option "--with-readline-dir=`brew --prefix readline`"

check_homebrew "openssl"
add_configure_option "--with-openssl-dir=`brew --prefix openssl`"

check_homebrew "libyaml"
add_configure_option "--with-libyaml-dir=`brew --prefix libyaml`"

readonly CONFIGURE_OPTIONS

echo "Using $SRCDIR"
echo "  CC: $CC"
echo "  CXX: $CXX"
echo "Options: $CONFIGURE_OPTIONS"

exec $SRCDIR/configure $CONFIGURE_OPTIONS | tee config.log
