module H2OConfigurator

  class Builder

    SitesDirGlob = '/Users/*/Sites/*'
    H2OEtcDir = '/usr/local/etc/h2o'
    H2OLogDir = '/usr/local/var/log/h2o'
    H2OConfFile = 'h2o.conf'
    AutoExtensionHandlerFile = 'auto-extension-handler.rb'
    RedirectHandlerFile = 'redirect-handler.rb'
    ErrorLogFile = 'error.log'
    DomainPrefixes = %w{www.}
    DomainSuffixes = %w{.dev}

    def initialize(make_dev: false)
      @make_dev = make_dev
      @host_dirs = Path.glob(SitesDirGlob).reject { |p| p.extname == '.old' }
      @etc_dir = Path.new(H2OEtcDir)
      @log_dir = Path.new(H2OLogDir)
      @config_file = @etc_dir / H2OConfFile
      @auto_extension_handler_file = Path.new(__FILE__).dirname / AutoExtensionHandlerFile
      @redirect_handler_file = Path.new(__FILE__).dirname / RedirectHandlerFile
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
          '/' => handlers_for_path('/', host_dir, host),
        },
      }
    end

    def handlers_for_path(path, host_dir, host)
      handlers = []
      htpasswd_file = host_dir / '.htpasswd'    #/
      if htpasswd_file.exist?
        handlers << {
          'mruby.handler' => %Q{
            require 'htpasswd'
            Htpasswd.new('#{htpasswd_file}', '#{host}')
          }.gsub(/\n\s+/, "\n").strip
        }
      end
      handlers << {
        'mruby.handler' => %Q{
          require '#{dest_handler_file(@redirect_handler_file)}'
          H2OConfigurator::RedirectHandler.new
        }.gsub(/\n\s+/, "\n").strip
      }
      handlers << {
        'mruby.handler' => %Q{
          require '#{dest_handler_file(@auto_extension_handler_file)}'
          H2OConfigurator::AutoExtensionHandler.new
        }.gsub(/\n\s+/, "\n").strip
      }
      handlers << { 'file.dir' => host_dir.to_s }
      handlers
    end

    def dest_handler_file(handler_file)
      @etc_dir / handler_file.basename
    end

    def write_config
      [@redirect_handler_file, @auto_extension_handler_file].each do |handler_file|
        handler_file.copy(dest_handler_file(handler_file))
      end
      @config_file.write(YAML.dump(make_config))
      check_config
    end

    def check_config
      system('h2o', '-t', '-c', @config_file.to_s)
      exit($?.to_i) unless $?.success?
    end

  end

end