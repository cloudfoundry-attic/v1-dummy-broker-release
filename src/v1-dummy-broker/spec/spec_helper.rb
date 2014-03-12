BROKER_SPEC_ROOT = File.dirname(__FILE__)

require File.expand_path('../../lib/dummy', __FILE__)
require File.expand_path('../vendor/integration-test-support/support/integration_example_group.rb', File.dirname(__FILE__))
require File.expand_path('../support/broker_runner', __FILE__)

IntegrationExampleGroup.tmp_dir = '/tmp'

RSpec.configure do |config|
  config.include IntegrationExampleGroup, type: :integration, example_group: {file_path: /\/integration\//}
end
