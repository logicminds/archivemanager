$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'rspec'
require 'rspec/mocks'
require 'archivemanager'
require 'mocha/api'
require 'mocha/setup'


require 'fakefs/spec_helpers'

RSpec.configure do | config|
  config.include FakeFS::SpecHelpers
end