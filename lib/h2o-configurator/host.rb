module H2OConfigurator

  class Host

    attr_accessor :dir
    attr_accessor :name

    def initialize(dir)
      @dir = dir
      @name = dir.basename.to_s
    end

    def make_config
      if cert_dir.exist?
        {
          "*.#{@name}:80" => make_https_redirect_host_config(80),
          "*.#{@name}:443" => make_host_config(443),
        }
      else
        {
          "*.#{@name}:80" => make_host_config(80),
        }
      end
    end

    def make_host_config(port)
      config = {
        'listen' => {
          'port' => port,
        },
        'access-log' => access_log_file.to_s,
        'setenv' => { 'HOST_DIR' => @dir.to_s },
        'paths' => {
          '/' => make_handlers,
        },
      }
      if server_certificate_file.exist? && private_key_file.exist?
        config['listen']['ssl'] = {
          'certificate-file' => server_certificate_file.to_s,
          'key-file' => private_key_file.to_s,
        }
      end
      config
    end

    def make_https_redirect_host_config(port)
      {
        'listen' => port,
        'paths' => {
          '/' => {
            'redirect' => "https://#{@name}",
          }
        }
      }
    end

    def make_handlers
      handlers = []
      if htpasswd_file.exist?
        handlers << make_ruby_handler(
          %Q{
            require 'htpasswd'
            Htpasswd.new('#{htpasswd_file}', '#{@name}')
          }
        )
      end
      handlers << make_ruby_external_handler('RedirectHandler')
      handlers << make_ruby_external_handler('AutoExtensionHandler')
      handlers << make_file_dir_handler(@dir)
      handlers
    end

    def make_ruby_handler(code)
      {
        'mruby.handler' => code.gsub(/\n\s+/, "\n").strip,
      }
    end

    def make_ruby_external_handler(klass)
      file = InstalledHandlersDir / H2OConfigurator::Handlers[klass]
      make_ruby_handler %Q{
        require '#{file}'
        H2OConfigurator::#{klass}.new
      }
    end

    def make_file_dir_handler(dir)
      {
        'file.dir' => dir.to_s,
      }
    end

    def cert_dir
      H2OConfigurator::CertBaseDir / @name
    end

    def server_certificate_file
      cert_dir / H2OConfigurator::ServerCertificateFilename
    end

    def private_key_file
      cert_dir / H2OConfigurator::PrivateKeyFilename
    end

    def htpasswd_file
      @dir / '.htpasswd'
    end

    def access_log_file
      H2OConfigurator::H2OLogDir / "#{@name}.access.log"
    end

  end

end