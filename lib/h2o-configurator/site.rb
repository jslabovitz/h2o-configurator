module H2OConfigurator

  class Site

    attr_accessor :dir
    attr_accessor :name

    def initialize(dir)
      @dir = dir
      @name = dir.basename.to_s
    end

    def make_config
      config = {}
      if cert_dir.exist?
        https_redirect_host_config = make_https_redirect_host_config(80)
        host_config = make_host_config(443)
      else
        https_redirect_host_config = nil
        host_config = make_host_config(80)
      end
      domains.each do |domain|
        if https_redirect_host_config
          config["#{domain}:80"] = https_redirect_host_config
          config["#{domain}:443"] = host_config
        else
          config["#{domain}:80"] = host_config
        end
      end
      config
    end

    def domains
      ([''] + DomainPrefixes).map do |prefix|
        ([''] + DomainSuffixes).map do |suffix|
          "#{prefix}#{@name}#{suffix}"
        end
      end.flatten
    end

    def make_host_config(port=80)
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

    def make_https_redirect_host_config(port=80)
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
      handlers << make_ruby_handler(
        %Q{
          require '#{H2OConfigurator::InstalledRedirectHandlerFile}'
          H2OConfigurator::RedirectHandler.new
        },
      )
      handlers << make_ruby_handler(
        %Q{
          require '#{H2OConfigurator::InstalledAutoExtensionHandlerFile}'
          H2OConfigurator::AutoExtensionHandler.new
        }
      )
      handlers << make_file_dir_handler(@dir)
      handlers
    end

    def make_ruby_handler(code)
      {
        'mruby.handler' => code.gsub(/\n\s+/, "\n").strip,
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