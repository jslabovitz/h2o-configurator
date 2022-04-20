module H2OConfigurator

  class Builder

    def initialize(site_dirs=nil)
      @site_dirs = site_dirs ? site_dirs.map { |p| Path.new(p).expand_path } : SitesDir.glob('*')
    end

    def make_config
      @site_dirs.reject! { |p| p.extname == '.old' || p.extname == '.new' }
      raise "No sites defined" if @site_dirs.empty?
      config = {
        'compress' => 'ON',
        'reproxy' => 'ON',
        'error-log' => ErrorLogFile.to_s,
        'hosts' => {},
      }
      @site_dirs.sort { |a, b| compare_domains(a.basename.to_s, b.basename.to_s) }.each do |dir|
        host = Host.new(dir)
        puts "%30s => %s" % [host.name, host.dir]
        config['hosts'].merge!(host.make_config)
      end
      config
    end

    def write_config
      H2OConfFile.write(YAML.dump(make_config))
      InstalledHandlersDir.rmtree if InstalledHandlersDir.exist?
      HandlersDir.cp_r(InstalledHandlersDir)
      H2OLogDir.mkpath
      check_config(H2OConfFile)
    end

    def check_config(file)
      system('h2o', '--mode=test', '--conf', file.to_s)
      raise Error, "h2o check failed: status #{$?.to_i}" unless $?.success?
    end

    def compare_domains(d1, d2)
      if d1 == d2
        0
      else
        compare_subdomains(d1.split('.').reverse, d2.split('.').reverse)
      end
    end

    def compare_subdomains(d1, d2)
      s1, s2 = d1.first, s2 = d2.first
      if s1 && !s2
        -1
      elsif !s1 && s2
        1
      elsif (r = s1 <=> s2) == 0
        compare_subdomains(d1[1..-1], d2[1..-1])
      else
        r
      end
    end

  end

end