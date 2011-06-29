# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Bestcrow::Application.initialize!

#Log4r
require 'log4r'
require 'log4r/yamlconfigurator'

require 'log4r/outputter/datefileoutputter'
require 'log4r/outputter/emailoutputter'
require 'log4r/outputter/udpoutputter'
require 'log4r/formatter/log4jxmlformatter'

log4r_config = Log4r::YamlConfigurator
log4r_config["HOME"] = Rails.root.to_s
log4r_config.load_yaml_file('config/log4r.yml')
