exec_ruby() {
  local path_to_ruby=$1; shift
  /usr/bin/env -i PATH="$PATH" HOME="$HOME" $path_to_ruby - $*
}

eval_rb_result() {
  # FIXME select ruby if it is in .rubies.
  eval "$(exec_ruby /usr/bin/ruby $*)"
}

rubies() {
  eval_rb_result $* << 'END_OF_RB'
    base_path = File.expand_path(".rubies", ENV["HOME"])
    $LOAD_PATH.unshift File.join(base_path, "src")
    require "rubies"
    rubies = Rubies.new(base_path)
    rubies.select!(ARGV.first) or exit 1
END_OF_RB
}

# vim:sw=2 ts=2 expandtab:
