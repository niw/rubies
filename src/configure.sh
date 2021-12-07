#!/usr/bin/env bash

set -euo pipefail

# Assume the parent directory has ruby source code.
readonly SRCDIR=${SRCDIR:-"../"}
echo "Using ruby source at $SRCDIR"

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

  RUBY_VERSION_MAJOR=$(sed -n 's/^#define RUBY_API_VERSION_MAJOR \(\d*\)/\1/p' "$SRCDIR/include/ruby/version.h")
  RUBY_VERSION_MINOR=$(sed -n 's/^#define RUBY_API_VERSION_MINOR \(\d*\)/\1/p' "$SRCDIR/include/ruby/version.h")
  RUBY_VERSION_TEENY=$(sed -n 's/^#define RUBY_VERSION_TEENY \(\d*\)/\1/p' "$SRCDIR/version.h")
  RUBY_VERSION="$RUBY_VERSION_MAJOR.$RUBY_VERSION_MINOR.$RUBY_VERSION_TEENY"
else
  RUBY_VERSION_MAJOR=$(echo "$RUBY_VERSION"|cut -d . -f 1)
  RUBY_VERSION_MINOR=$(echo "$RUBY_VERSION"|cut -d . -f 2)
  RUBY_VERSION_TEENY=$(echo "$RUBY_VERSION"|cut -d . -f 3)
fi
readonly RUBY_VERSION_MAJOR
readonly RUBY_VERSION_MINOR
readonly RUBY_VERSION_TEENY
readonly RUBY_VERSION

# Read patch level from `version.h`.
RUBY_PATCHLEVEL=$(sed -n 's/^#define RUBY_PATCHLEVEL \([-0-9]*\)/\1/p' "$SRCDIR/version.h")
if [[ "$RUBY_PATCHLEVEL" = "-1" ]]; then
  RUBY_PATCHLEVEL="dev"
else
  RUBY_PATCHLEVEL="p$RUBY_PATCHLEVEL"
fi
readonly RUBY_PATCHLEVEL

echo "Ruby version: $RUBY_VERSION_MAJOR.$RUBY_VERSION_MINOR.$RUBY_VERSION_TEENY-$RUBY_PATCHLEVEL"

if [[ $RUBY_VERSION_MAJOR -eq 1 && $RUBY_VERSION_MINOR -lt 9 || ($RUBY_VERSION_MAJOR -eq 1 && $RUBY_VERSION_MINOR -eq 9 && $RUBY_VERSION_TEENY -lt 3) ]]; then
  echo "Ruby prior to 1.9.3 is not supported." >&2
  exit 1
fi


# Default `prefix` is like `~/.rubies/ruby-2.1.0` or `~/.rubies/ruby-1.9.0-p551`
if [[ ! -z ${1:-} ]]; then
  PREFIX="ruby-$1"
else
  if [[ $RUBY_VERSION_MAJOR -lt 2 || ( $RUBY_VERSION_MAJOR -eq 2 && $RUBY_VERSION_MINOR < 1 ) ]]; then
    PREFIX="ruby-$RUBY_VERSION-$RUBY_PATCHLEVEL"
  else
    PREFIX="ruby-$RUBY_VERSION"
  fi
fi
readonly PREFIX


CONFIGURE_OPTIONS="
  --prefix $HOME/.rubies/$PREFIX \
  --enable-shared \
  --enable-install-static-library \
  --disable-install-doc \
  --without-tk \
  --without-gdbm \
  ${CONFIGURE_OPTIONS:-}
"

if ! type pkg-config >/dev/null 2>&1; then
  echo "pkg-config is not found." >&2
  exit 1
fi
readonly PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}

# Check if there is Homebrew or not.
if type brew >/dev/null 2>&1; then
  HAS_HOMEBREW=1
else
  HAS_HOMEBREW=0
fi
readonly HAS_HOMEBREW

# Use pkg-config to find `prefix` for each library.
ensure_library() {
  local -r pkg_name=$1
  local -r brew_name=${2:-$pkg_name}
  local -r lib_name=${3:-$pkg_name}

  local prefix
  if ! prefix=$(pkg-config --variable=prefix "$pkg_name" 2>/dev/null); then
    # If we have Homebrew, try again with additional `PKG_CONFIG_PATH`, that may be
    # only available in each cellar.
    if (( HAS_HOMEBREW )); then
      local pkg_config_path
      pkg_config_path="$PKG_CONFIG_PATH:$(brew --prefix "$brew_name" 2>/dev/null)/lib/pkgconfig"
      readonly pkg_config_path
      if ! prefix=$(env PKG_CONFIG_PATH="$pkg_config_path" pkg-config --variable=prefix "$pkg_name" 2>/dev/null); then
        echo "$1 is not found" >&2
        exit 1
      fi
    else
      echo "$1 is not found" >&2
      exit 1
    fi
  fi
  readonly prefix

  CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --with-${lib_name}-dir=${prefix}"
}

# Not all, but default library used by Ruby.
ensure_library readline
ensure_library openssl openssl@1.1

# Prior to Ruby 2.0.0, it doesn't have embedded libyaml.
if [[ $RUBY_VERSION_MAJOR -eq 1 ]]; then
  ensure_library yaml-0.1 libyaml libyaml
fi

readonly CONFIGURE_OPTIONS


CFLAGS=${CFLAGS:-}

# Prior to Ruby 2.3.0, it `mkmf.rb` uses conftest code that causes implicit function declaration warning,
# which causes an error on clang.
if [[ $RUBY_VERSION_MAJOR -eq 1 || ($RUBY_VERSION_MAJOR -eq 2 && $RUBY_VERSION_MINOR < 3) ]]; then
  CFLAGS="$CFLAGS -Wno-implicit-function-declaration"
fi
readonly CFLAGS
export CFLAGS


echo "Source: $SRCDIR"
echo "Options: $CONFIGURE_OPTIONS"
echo "CFLAGS: $CFLAGS"

"$SRCDIR/configure" $CONFIGURE_OPTIONS | tee config.log
