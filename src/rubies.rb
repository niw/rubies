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
      if gem_home = gem_home(File.join(ruby_bin, "ruby"))
        gem_bin = File.join(gem_home, "bin")
        paths.unshift(gem_bin)
      end
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

  def gem_home(ruby)
    ruby_version = %x(#{ruby} -rrbconfig -e 'print RbConfig::CONFIG["ruby_version"]') rescue nil
    return nil unless ruby_version
    File.join(base_path, "gems", ruby_version)
  end

  def ruby_path(name)
    path = Dir.glob(File.join(base_path, "#{name}*")).reject{|path|
      !File.exist?(File.join(path, "bin", "ruby"))}.sort.first
    return nil unless path
    File.expand_path(File.readlink(path), File.dirname(path)) rescue path
  end
end
