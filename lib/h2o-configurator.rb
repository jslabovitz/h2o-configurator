require 'path'
require 'yaml'

require 'h2o-configurator/builder'
require 'h2o-configurator/site'
require 'h2o-configurator/version'

module H2OConfigurator

  SitesDirGlob = '/Users/*/Sites/*'
  H2OEtcDir = Path.new('/usr/local/etc/h2o')
  H2OLogDir = Path.new('/usr/local/var/log/h2o')
  H2OConfFile = H2OEtcDir / 'h2o.conf'
  HandlersDir = Path.new(__FILE__).dirname / 'h2o-configurator' / 'handlers'
  InstalledHandlersDir = H2OEtcDir / 'handlers'
  Handlers = {
    'AutoExtensionHandler'  => 'auto-extension.rb',
    'RedirectHandler'       => 'redirect.rb',
  }
  ErrorLogFile = H2OLogDir / 'error.log'
  CertBaseDir = Path.new('/etc/letsencrypt/live')
  ServerCertificateFilename = 'fullchain.pem'
  PrivateKeyFilename = 'privkey.pem'
  DomainPrefixes = %w{www.}
  DomainSuffixes = %w{.test}

  class Error < Exception; end

end