_rubies_exec_ruby() {
  local -r path_to_ruby="$1"
  shift
  exec /usr/bin/env -i PATH="$PATH" HOME="$HOME" "$path_to_ruby" --disable=gems - "$@"
}

_rubies_eval_rb_result() {
  # FIXME select ruby if it is in .rubies.
  eval "$(_rubies_exec_ruby /usr/bin/ruby "$@")"
}

rubies() {
  _rubies_eval_rb_result "$@" << 'END_OF_RB'
    base_path = File.expand_path(".rubies", ENV["HOME"])
    $LOAD_PATH.unshift File.join(base_path, "src")
    require "rubies"
    rubies = Rubies.new(base_path)
    rubies.run!
END_OF_RB
}

# rbs means rubies or ruby switch.
alias rbs=rubies

_rubies_cd_hook() {
  local current_dir="$(pwd -P)"
  local rcfile

  while : ; do
    if [[ -f "$current_dir/.rubiesrc" ]]; then
      rcfile="$current_dir/.rubiesrc"
      break
    fi
    if [[ -f "$current_dir/.rvmrc" ]]; then
      rcfile="$current_dir/.rvmrc"
      break
    fi
    if [[ -z "$current_dir" \
      || "$current_dir" = "$HOME" \
      || "$current_dir" = "/" \
      || "$current_dir" = "." ]]; then
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
  readonly rcfile

  if [[ ! "$RUBIES_LAST_RC_FILE" = "$rcfile" ]]; then
    rubies -c "$rcfile"
    export RUBIES_LAST_RC_FILE="$rcfile"
  fi
}

enable_rubies_cd_hook() {
  # Only when we can use zsh chpwd_functions, use it.
  if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz is-at-least
    if is-at-least 4.3.4 >/dev/null 2>&1; then
      # Force to read rubiesrc file first.
      export RUBIES_LAST_RC_FILE=
      _rubies_cd_hook

      typeset -gaU chpwd_functions
      chpwd_functions+=_rubies_cd_hook
      return 0
    fi
  fi
  return 1
}
