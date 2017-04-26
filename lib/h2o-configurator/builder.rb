module H2OConfigurator

  class Builder

    def initialize
      @host_dirs = Path.glob('/Users/*/Sites/*').reject { |p| p.extname == '.old' }
      @etc_dir = Path.new('/usr/local/etc/h2o')
      @log_dir = Path.new('/usr/local/var/log/h2o')
      @config_file = @etc_dir / 'h2o.conf'
      @mruby_handler_file = Path.new(__FILE__).dirname / 'mruby-handler.rb'
      raise "mruby_handler_file doesn't exist at #{@mruby_handler_file}" unless @mruby_handler_file.exist?
      @error_file = @log_dir / 'error.log'
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
      ['', 'www.'].map do |prefix|
        ['', '.dev'].map do |suffix|
          "#{prefix}#{host}#{suffix}"
        end
      end.flatten
    end

    def config_for_host(host, host_dir)
      {
        'access-log' => (@log_dir / "#{host}.access.log").to_s,
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
      @etc_dir / @mruby_handler_file.basename
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