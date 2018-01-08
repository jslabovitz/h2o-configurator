module H2OConfigurator

  SitesDirGlob = '/Users/*/Sites/*'
  H2OEtcDir = Path.new('/usr/local/etc/h2o')
  H2OLogDir = Path.new('/usr/local/var/log/h2o')
  H2OConfFile = H2OEtcDir / 'h2o.conf'
  AutoExtensionHandlerFile = Path.new(__FILE__).dirname / 'auto-extension-handler.rb'
  RedirectHandlerFile = Path.new(__FILE__).dirname / 'redirect-handler.rb'
  InstalledAutoExtensionHandlerFile = H2OEtcDir / AutoExtensionHandlerFile.basename
  InstalledRedirectHandlerFile = H2OEtcDir / RedirectHandlerFile.basename
  ErrorLogFile = H2OLogDir / 'error.log'
  CertBaseDir = Path.new('/etc/letsencrypt/live')
  ServerCertificateFilename = 'fullchain.pem'
  PrivateKeyFilename = 'privkey.pem'
  DomainPrefixes = %w{www.}
  DomainSuffixes = %w{.test}

  class Builder

    def initialize
      H2OLogDir.mkpath
    end

    def make_config
      config = {
        'compress' => 'ON',
        'reproxy' => 'ON',
        'error-log' => ErrorLogFile.to_s,
        # 'listen' => 80,
        'hosts' => {},
      }
      Path.glob(SitesDirGlob).reject { |p| p.extname == '.old' || p.extname == '.new' }.each do |site_dir|
        site = Site.new(site_dir)
        config['hosts'].merge!(site.make_config)
      end
      config
    end

    def write_config
      RedirectHandlerFile.copy(InstalledRedirectHandlerFile)
      AutoExtensionHandlerFile.copy(InstalledAutoExtensionHandlerFile)
      H2OConfFile.write(YAML.dump(make_config))
      check_config
    end

    def check_config
      system('h2o', '-t', '-c', H2OConfFile.to_s)
      exit($?.to_i) unless $?.success?
    end

  end

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
        handlers << RubyHandler.make(
          %Q{
            require 'htpasswd'
            Htpasswd.new('#{htpasswd_file}', '#{@name}')
          }
        )
      end
      handlers << RubyHandler.make(
        %Q{
          require '#{H2OConfigurator::InstalledRedirectHandlerFile}'
          H2OConfigurator::RedirectHandler.new
        },
      )
      handlers << RubyHandler.make(
        %Q{
          require '#{H2OConfigurator::InstalledAutoExtensionHandlerFile}'
          H2OConfigurator::AutoExtensionHandler.new
        }
      )
      handlers << FileDirHandler.make(@dir)
      handlers
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

  class RubyHandler

    def self.make(code)
      {
        'mruby.handler' => code.gsub(/\n\s+/, "\n").strip,
      }
    end

  end

  class FileDirHandler

    def self.make(dir)
      {
        'file.dir' => dir.to_s,
      }
    end

  end

end