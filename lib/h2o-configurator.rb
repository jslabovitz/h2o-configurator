require 'path'
require 'yaml'

require 'h2o-configurator/builder'
require 'h2o-configurator/host'
require 'h2o-configurator/version'

module H2OConfigurator

  SitesDirGlob = '/Users/*/Sites/*'
  RootDir = Path.new(ENV['HOMEBREW_PREFIX'] || '/usr/local')
  H2OEtcDir = RootDir / 'etc/h2o'
  H2OLogDir = RootDir / 'var/log/h2o'
  H2OConfFile = H2OEtcDir / 'h2o.conf'
  HandlersDir = Path.new(__FILE__).dirname / 'h2o-configurator' / 'handlers'
  InstalledHandlersDir = H2OEtcDir / 'handlers'
  Handlers = {
    'AutoExtensionHandler'  => 'auto-extension.rb',
    'RedirectHandler'       => 'redirect.rb',
  }
  ErrorLogFile = H2OLogDir / 'error.log'
  CertificatesBaseDir = H2OEtcDir / 'certificates'

  class Error < Exception; end

end