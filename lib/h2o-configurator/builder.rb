module H2OConfigurator

  class Builder

    def make_config
      config = {
        'compress' => 'ON',
        'reproxy' => 'ON',
        'error-log' => ErrorLogFile.to_s,
        'hosts' => {},
      }
      Path.glob(SitesDirGlob).reject { |p| p.extname == '.old' || p.extname == '.new' }.each do |site_dir|
        site = Site.new(site_dir)
        puts "%30s => %s" % [site.name, site.dir]
        config['hosts'].merge!(site.make_config)
      end
      config
    end

    def write_config
      new_file = H2OConfFile.add_extension('.new')
      new_file.write(YAML.dump(make_config))
      check_config(new_file)
      new_file.mv(H2OConfFile)
      RedirectHandlerFile.copy(InstalledRedirectHandlerFile)
      AutoExtensionHandlerFile.copy(InstalledAutoExtensionHandlerFile)
      H2OLogDir.mkpath
    end

    def check_config(file)
      system('h2o', '--mode=test', '--conf', file.to_s)
      raise Error, "h2o check failed: status #{$?.to_i}" unless $?.success?
    end

  end

end