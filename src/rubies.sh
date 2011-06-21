_rubies_exec_ruby() {
  local path_to_ruby=$1; shift
  /usr/bin/env -i PATH="$PATH" HOME="$HOME" $path_to_ruby - $*
}

_rubies_eval_rb_result() {
  # FIXME select ruby if it is in .rubies.
  eval "$(_rubies_exec_ruby /usr/bin/ruby $*)"
}

rubies() {
  _rubies_eval_rb_result $* << 'END_OF_RB'
    base_path = File.expand_path(".rubies", ENV["HOME"])
    $LOAD_PATH.unshift File.join(base_path, "src")
    require "rubies"
    rubies = Rubies.new(base_path)
    rubies.select!(ARGV.first)
END_OF_RB
}

# rbs means rubies or ruby switch.
alias rbs=rubies

_rubies_cd_hook() {
  local current_dir="$PWD"
  local args

  while : ; do
    if [ -f "$current_dir/.rubiesrc" ]; then
      args=$(cat "$current_dir/.rubiesrc")
      break
    fi
    # FIXME remove this once migrate rvm to rubies.
    if [ -f "$current_dir/.rvmrc" ]; then
      args=$(cat "$current_dir/.rvmrc" | grep rvm | sed -E 's/^rvm ([^@]+).*/\1/g')
      break
    fi
    if [ -z "$current_dir" -o "$current_dir" = "$HOME" -o "$current_dir" = "/" ]; then
      args="default"
      break
    fi
    current_dir=$(dirname "$current_dir")
  done

  # We can switch ruby anytime by rubies command, and it will keeps
  # until we're not going out from the direcoty.
  if [ ! "$RUBIES_LAST_RUBIES_ARGS" = "$args" ]; then
    rubies $args
    export RUBIES_LAST_RUBIES_ARGS="$args"
  fi
}

enable_rubies_cd_hook() {
  # If we could use zsh chpwd_functions, use it.
  if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz is-at-least
    if is-at-least 4.3.4 >/dev/null 2>&1; then
      chpwd_functions=("${chpwd_functions[@]}" _rubies_cd_hook)
      return
    fi
  fi

  # Otherwise, overwrite cd.
  cd() {
    builtin cd "$@"
    local result=$?
    _rubies_cd_hook
    return $result
  }
}

# vim:sw=2 ts=2 expandtab:
