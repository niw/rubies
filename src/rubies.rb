require "yaml"

class Rubies
  attr_reader :base_path

  def initialize(*base_path)
    @base_path = File.expand_path(*base_path)
  end

  def run!
    name = ARGV.shift
    if /^-c/ === name
      name = load_rcfile(ARGV.shift)
    end
    select(name)
  end

  private

  def load_rcfile(path)
    rcfile = File.read(path)
    if File.basename(path) == ".rvmrc"
      rcfile[/^rvm ([^@]+)/, 1]
    else
      YAML.load(rcfile)["ruby"]
    end
  rescue
    nil
  end

  def select(name)
    paths = paths_without_rubies
    ruby_name = nil
    # FIXME keep original GEM_HOME
    gem_home = nil

    if name && ruby_path = ruby_path(name)
      ruby_name = File.basename(ruby_path)
      ruby_bin = File.join(ruby_path, "bin")

      gem_home = gem_home(ruby_name)
      gem_bin = File.join(gem_home, "bin")

      paths.unshift(gem_bin)
      paths.unshift(ruby_bin)
    end

    export "PATH", paths.uniq.join(":")
    export "GEM_HOME", gem_home
    export "RUBIES_RUBY_NAME", ruby_name
  end

  def export(name, value = nil)
    if value
      puts %(export #{name}="#{value}")
    else
      puts %(unset #{name})
    end
  end

  def paths_without_rubies
    ENV["PATH"].split(/:/).reject do |path|
      path = File.expand_path(path)
      path.start_with?(base_path)
    end
  end

  def gem_home(ruby_name)
    File.join(base_path, "gems", ruby_name)
  end

  def ruby_path(name)
    path = find_name_in_paths(name, ruby_paths)
    return nil unless path
    File.expand_path(File.readlink(path), File.dirname(path)) rescue path
  end

  def find_name_in_paths(name, paths)
    name = name.split(/\W/)
    paths = paths.inject({}) do |hash, path|
      hash[File.basename(path).split(/\W/)] = path
      hash
    end

    keys = []
    paths.keys.each do |key|
      return paths[key] if key == name
      if (0..(key.size - name.size)).find{|index| key[index, name.size] == name}
        keys << key
      end
    end

    key = keys.sort.last
    paths[key] if key
  end

  def ruby_paths
    Dir.glob(File.join(base_path, "*")).reject do |path|
      !File.exist?(File.join(path, "bin", "ruby"))
    end
  end
end
