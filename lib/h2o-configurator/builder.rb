module H2OConfigurator

  class Builder

    def make_config
      config = {
        'compress' => 'ON',
        'reproxy' => 'ON',
        'error-log' => ErrorLogFile.to_s,
        'hosts' => {},
      }
      Path.glob(SitesDirGlob).reject { |p| p.extname == '.old' || p.extname == '.new' }.sort.each do |dir|
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

  end

end