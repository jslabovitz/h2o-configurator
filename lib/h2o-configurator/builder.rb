module H2OConfigurator

  class Builder

    SitesDirGlob = '/Users/*/Sites/*'
    H2OEtcDir = '/usr/local/etc/h2o'
    H2OLogDir = '/usr/local/var/log/h2o'
    H2OConfFile = 'h2o.conf'
    MRubyHandlerFile = 'mruby-handler.rb'
    ErrorLogFile = 'error.log'
    DomainPrefixes = %w{www.}
    DomainSuffixes = %w{.dev}

    def initialize(make_dev: false)
      @make_dev = make_dev
      @host_dirs = Path.glob(SitesDirGlob).reject { |p| p.extname == '.old' }
      @etc_dir = Path.new(H2OEtcDir)
      @log_dir = Path.new(H2OLogDir)
      @config_file = @etc_dir / H2OConfFile
      @mruby_handler_file = Path.new(__FILE__).dirname / MRubyHandlerFile
      raise "mruby_handler_file doesn't exist at #{@mruby_handler_file}" unless @mruby_handler_file.exist?
      @error_file = @log_dir / ErrorLogFile
      @log_dir.mkpath
    end

    def make_config
      config = {
        'compress' => 'ON',
        'reproxy' => 'ON',
        'error-log' => @error_file.to_s,
        'listen' => 80,
        'hosts' => {},
      }
      @host_dirs.each do |host_dir|
        host = host_dir.basename.to_s
        host_config = config_for_host(host, host_dir)
        domains_for_host(host).each do |domain|
          config['hosts'][domain] = host_config
        end
      end
      config
    end

    def domains_for_host(host)
      ([''] + DomainPrefixes).map do |prefix|
        ([''] + (@make_dev ? DomainSuffixes : [])).map do |suffix|
          "#{prefix}#{host}#{suffix}"
        end
      end.flatten
    end

    def config_for_host(host, host_dir)
      host_access_log = @log_dir / "#{host}.access.log"   #/
      {
        'access-log' => host_access_log.to_s,
        'setenv' => { 'HOST_DIR' => host_dir.to_s },
        'paths' => {
          '/' => {
            'mruby.handler-file' => dest_mruby_handler_file.to_s,
            'file.dir' => host_dir.to_s,
          },
        },
      }
    end

    def dest_mruby_handler_file
      @etc_dir / @mruby_handler_file.basename   #/
    end

    def write_config
      @mruby_handler_file.copy(dest_mruby_handler_file)
      @config_file.write(YAML.dump(make_config))
      check_config
    end

    def check_config
      system('h2o', '-t', '-c', @config_file.to_s)
      exit($?) unless $? == 0
    end

  end

end