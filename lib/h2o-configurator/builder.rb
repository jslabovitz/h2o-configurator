module H2OConfigurator

  class Builder

    def initialize(*site_dirs)
      @site_dirs = site_dirs.empty? ? SitesDir.glob('*') : site_dirs.map { |p| Path.new(p).expand_path }
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

    def write_config(install: true)
      config_yaml = YAML.dump(make_config)
      if install
        H2OConfFile.write(config_yaml)
        InstalledHandlersDir.rmtree if InstalledHandlersDir.exist?
        HandlersDir.cp_r(InstalledHandlersDir)
        H2OLogDir.mkpath
        check_config(H2OConfFile)
      else
        config_file = Path.new('/tmp') / H2OConfFile.base
        config_file.write(config_yaml)
        puts "\# config file written to #{config_file}"
        puts "\# run the following in your shell:"
        puts "sudo cp #{config_file} #{H2OConfFile.dir}"
        puts "sudo rm -rf #{InstalledHandlersDir}"
        puts "sudo cp -r #{HandlersDir} #{InstalledHandlersDir.dir}"
        puts "h2o --mode=test --conf #{H2OConfFile}"
        puts "\# restart the h2o server"
      end
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