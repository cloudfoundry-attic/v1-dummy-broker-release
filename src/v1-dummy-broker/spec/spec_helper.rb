require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

BROKER_SPEC_ROOT = File.dirname(__FILE__)

require File.expand_path('../../lib/dummy', __FILE__)
require File.expand_path('../vendor/integration-test-support/support/integration_example_group.rb', File.dirname(__FILE__))
require File.expand_path('../support/broker_runner', __FILE__)
