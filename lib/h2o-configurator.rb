require 'path'
require 'yaml'
require 'pp'

class H2OConfigurator

  def initialize
    @host_dirs = Path.glob('/Users/*/Sites/*')
    @etc_dir = Path.new('/usr/local/etc/h2o')
    @log_dir = Path.new('/usr/local/var/log/h2o')
    @config_file = @etc_dir / 'h2o.conf'
    @untyped_handler_file = @etc_dir / 'untyped-handler.rb'
    raise "untyped_handler_file doesn't exist at #{@untyped_handler_file}" unless @untyped_handler_file.exist?
    @error_file = @log_dir / 'error.log'
    @log_dir.mkpath
  end

  def make_config
    config = {
      'compress' => 'ON',
      'reproxy' => 'ON',
      'error-log' => @error_file.to_s,
      'hosts' => {},
    }
    @host_dirs.each do |host_dir|
      host = host_dir.basename.to_s
      host_config = make_host_config(host, host_dir)
      host_keys = {
        host => 80,
        "www.#{host}" => 80,
        "#{host}.dev" => 80,
      }
      host_keys.each do |key, port|
        config['hosts'].merge!("#{key}:#{port}" => host_config.merge('listen' => port))
      end
    end
    config
  end

  def make_host_config(host, host_dir)
    host_access_file = @log_dir / "#{host}.access.log"
    host_config = {
      'paths' => {
        '/' => {
          'file.dir' => host_dir.to_s,
          'mruby.handler-file' => @untyped_handler_file.to_s,
          'access-log' => host_access_file.to_s,
        },
      },
    }
    host_dir.glob('**/*.redirect').each do |redirect_file|
      from_uri = '/' + redirect_file.basename.without_extension.to_s
      data = redirect_file.read
      if data =~ /^--/
        redirect = YAML.load(data)
        to_uri, code = redirect[:uri], redirect[:code]
      else
        to_uri, code = data.split(' ')
      end
      to_uri = '/' + to_uri unless to_uri.start_with?('/')
      host_config['paths'][from_uri] = {
        'redirect' => {
          'status' => code.to_i,
          'url' => to_uri,
        },
      }
    end
    host_config
  end

  def write_config
    @config_file.write(YAML.dump(make_config))
  end

  def check_config
    system('h2o', '-t', '-c', @config_file.to_s)
    exit($?) unless $? == 0
  end

end