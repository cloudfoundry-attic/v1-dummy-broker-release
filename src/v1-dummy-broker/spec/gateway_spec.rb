require 'securerandom'
require 'spec_helper'

describe Dummy::Gateway do
  let(:gateway) { Dummy::Gateway.new }
  ENV['IP_ROUTE'] = 'localhost'
  ENV['PID_FILE'] = '/tmp/testing-broker.pid'
  ENV['NATS_URI'] = 'nats://localhost:1234'
  ENV['UAA_CLIENT_ID'] = 'test-dummy-broker'
  ENV['UAA_ENDPOINT'] = 'http://localhost:5678'
  ENV['UAA_USERNAME'] = 'dummy-user'
  ENV['UAA_PASSWORD'] = 'dummy-password'
  ENV['CLOUD_CONTROLLER_URI'] = 'http://localhost:9999'
  ENV['SERVICE_UNIQUE_ID'] = SecureRandom.uuid
  ENV['PLAN_UNIQUE_ID'] = SecureRandom.uuid

  describe '#default_config_file' do
    it 'returns a Pathname pointing to the configuration file' do
      path = File.expand_path('../../config/config.yml', __FILE__)
      expect(gateway.default_config_file).to eql(Pathname.new(path))
      expect(File.exist?(path)).to be_true
    end
  end

  describe 'required configuration' do
    it 'sets the required configuration values' do
      gateway.load_config
      config = gateway.config.dup
      logger = config.delete(:logger)

      expect(logger).to be_instance_of(Steno::Logger)
      expect(config).to eq({
        cc_api_version: 'v2',
        service_auth_tokens: {
          dummy_test: '36001246-f5d0-4d9a-aa33-7d2522fe1ea7'
        },
        token: '36001246-f5d0-4d9a-aa33-7d2522fe1ea7',
        ip_route: ENV['IP_ROUTE'],
        service: {
          name: 'v1-test',
          version: 'n/a',
          provider: 'pivotal-software',
          provider_name: 'Pivotal Software',
          unique_id: ENV['SERVICE_UNIQUE_ID'],
          description: 'A test service offered by a mock v1 broker',
          logo_url: '/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAMCAgMNAgMDCwMEAwMEBQgFBQQEBQoHBwYIDAoMFQsKCwsNDhIQDQ4RDgsJEBYQERMUFQsVDAoXGBYPGBIUFQ8BAwQEBgUGCgYGCgwLCw0QEQ8UDREPDA0OEw0MDwwPEA0QDQ4QDQsODhANDQ0NEAwKDA8UDwwNDQwPDAwOEAwMDf/AABEIADAAMAMBEQACEQEDEQH/xAAdAAACAQQDAAAAAAAAAAAAAAAABwgDBAUGAQIJ/8QAMhAAAQMDAgIIAwkAAAAAAAAAAQIDBAAFEQYSCCEHCRMxQVF0sxQiOBYoNlJUgpGSsv/EABwBAAICAwEBAAAAAAAAAAAAAAAEAwYCBQcBCP/EADQRAAEDAgMFBQUJAAAAAAAAAAEAAgMEEQYhUQUxQXGBEjM1kbIUQmHC8RMiMlJigqGxwf/aAAwDAQACEQMRAD8AQlWtfMS7IQoqCQkqUe4AZNeE2XrWlxsBdVfgZP6d3+hrHtt1Cm9nl/K7yKoqSQvYQUq/Krka9uFEWObvFlxWSxRQhFCE4OEM/eT0H6xz2HaUqu7Ks2G/EYuvpK9AeIbijtVquNkiO2ObdjdGnXUKiOoTs7MpBB3ee8fxWnihMt7Lq21dtR7NLRI1zu1fdbhbXmtK0NxYdFF1vMfSEjTamJc89nGYv0Rl+O+vwQlYKtq+XLITk4AOSAZX08kQ7Q/ha6l27QbSf7O9mZ3BwBBOnHPnb4ZqMXGdw5W+3anttzjJcb01eu07OMtRX8G8jG5sKPMpIUCnOSMLGeQp+lnLxZ28Kk4k2Oyie2WEWY6+WhHDkeF/io4U+qUihCcHCH9Seg/WOew7SlV3ZVmw34jF19Lk9+swQo6m6PkBJWtUWYEpSMknezyFJ0PvK0YzBLoAP1fKkZw2dDurZHS5pOQ3ZZzNut9zjzpdxdjrbYZbadSpXzkY3EJwEjmSR4ZIbnlaGEXVZ2Lsyplq43Bjg1rg4uIIFmkHfroFJnrLr/D+yWi7JvSbg9PdmhA5lLSGykk+QJdTjz2q8qRoh94lXPGUzRBHFxLr9ALf6oBVulyRFCE4OEP6k9B+sc9h2lKruyrNhvxGLr6XKSnHpqZEfpf6HdQlhUpFpecnKYQvYpwNvx1bQcHGduM+FIUre017dQrniecU9TSzEX7JJtyLSsVqPrMZRhrbj6EZjyin5H7lcC6hB8MtoQkqH7xWbaHUpWbGmVoos9Scr8gM/MKIvSH0i3+bqqVqGVPVPuT+E7sbUNNjO1ttI5JQMnAHmSckknZRxhgsFz6trZayUzTG5PkBoBwH133WtVKkUUITg4Q/qT0H6xz2HaUqu7Ks2G/EYuvpcnr1mn4j0B6SZ/tmlKH3lZsab4f3fKoVVtlzNFCEUIRQhXVtucxuczNblyIE1k7mpMV1TTjZx3pUkgjkT3ViWgixUkcr4nB8ZLSOIyKur7qq9vLZW/ebjeFsghpVwluSC2D3hJWTjOB3d+BXjWNb+EWUs9VNPb7V7nW1JP8AaxdZpZFCEUIX/9k=',
          plans: {
            free: {
              unique_id: ENV['PLAN_UNIQUE_ID'],
              description: 'A test plan offered by a mock v1 broker',
              free: true,
              extra: '{"bullets":["Gates code promotion in CI","Ensures continued support in CF v2 for v1 service brokers"]}'
            }
          }
        },
        logging: {
          level: 'debug'
        },
        pid: ENV['PID_FILE'],
        mbus: ENV['NATS_URI'],
        uaa_client_id: ENV['UAA_CLIENT_ID'],
        uaa_endpoint: ENV['UAA_ENDPOINT'],
        uaa_client_auth_credentials: {
          username: ENV['UAA_USERNAME'],
          password: ENV['UAA_PASSWORD']
        },
        cloud_controller_uri: ENV['CLOUD_CONTROLLER_URI']
      })
    end
  end

  describe '#provisioner_class' do
    it 'returns the class to be used for provisioning' do
      expect(gateway.provisioner_class).to eql(Dummy::Provisioner)
    end
  end

  describe '#provisioner_config' do
    before { gateway.load_config }

    it 'returns a hash containing the provisioner configuration' do
      expect(gateway.provisioner_config.keys).to eql([
        :logger,
        :index,
        :ip_route,
        :mbus,
        :node_timeout,
        :z_interval,
        :max_nats_payload,
        :additional_options,
        :status,
        :plan_management,
        :service,
        :download_url_template,
        :cc_api_version,
        :snapshot_db
      ])
    end
  end

end
