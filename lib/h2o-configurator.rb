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
  AutoExtensionHandlerFile = Path.new(__FILE__).dirname / 'h2o-configurator' / 'auto-extension-handler.rb'
  RedirectHandlerFile = Path.new(__FILE__).dirname / 'h2o-configurator' / 'redirect-handler.rb'
  InstalledAutoExtensionHandlerFile = H2OEtcDir / AutoExtensionHandlerFile.basename
  InstalledRedirectHandlerFile = H2OEtcDir / RedirectHandlerFile.basename
  ErrorLogFile = H2OLogDir / 'error.log'
  CertBaseDir = Path.new('/etc/letsencrypt/live')
  ServerCertificateFilename = 'fullchain.pem'
  PrivateKeyFilename = 'privkey.pem'
  DomainPrefixes = %w{www.}
  DomainSuffixes = %w{.test}

  class Error < Exception; end

end