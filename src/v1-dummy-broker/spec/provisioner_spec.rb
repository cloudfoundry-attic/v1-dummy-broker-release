require 'spec_helper'

describe Dummy::Provisioner do
  let(:provisioner) { Dummy::Provisioner.new(options) }
  let(:options)     { gateway.provisioner_config }
  let(:gateway)     { Dummy::Gateway.new.tap { |g| g.load_config } }

  before { Thread.new { EM.run {} } }
  after  { EM.stop }

  describe '#initialize' do
    it 'takes a set of options' do
      expect(provisioner.options).to eql(options)
    end
  end

  describe '#service_name' do
    it 'returns the name of the service' do
      expect(provisioner.service_name).to eql('Dummy')
    end
  end
end
