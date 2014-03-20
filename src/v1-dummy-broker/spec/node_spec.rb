require 'spec_helper'

describe Dummy::Node do

  subject(:node) { described_class.new(opts) }

  let(:opts) do
    {
      logger: Logger.new(STDOUT),
      ip_route: local_ip
    }
  end

  let(:plan) { 'free' }
  let(:credentials) { nil }
  let(:version) { nil }
  let(:local_ip) { '127.0.0.1' }

  before do
    allow(EM).to receive(:start_server)
  end

  describe 'initialize' do
    it 'starts an EM server with the BindingHttpHandler with the right host and port' do
      allow(VCAP).to receive(:grab_ephemeral_port).and_return(1234)
      node = Dummy::Node.new(opts)
      expect(EM).to have_received(:start_server).with(local_ip, 1234, BindingHttpHandler, node)
    end
  end

  describe '#service_name' do
    it 'returns the name of the service' do
      expect(node.service_name).to eql('Dummy')
    end
  end

  describe 'provision' do
    it 'creates and stores a new instance id' do
      expect(node.instances).to be_empty

      node.provision(plan, credentials, version)

      expect(node.instances).to_not be_empty
    end


    it 'returns the instance id' do
      result = node.provision(plan, credentials, version)

      expect(result).to eq({ 'name' => node.instances.keys.first })
    end

    it 'maintains a large random number associated with the service instance' do
      allow(SecureRandom).to receive(:uuid).and_return('service-instance-id', 'some-large-string')

      expect(node.instances).to be_empty
      result = node.provision(plan, credentials, version)
      name = result['name']
      expect(node.instances[name]).to eq 'some-large-string'
    end
  end

  describe 'announcement' do
    it 'returns the available capacity' do
      expect(node.announcement['available_capacity']).to be_a Integer
    end

    it 'returns the capacity unit' do
      expect(node.announcement['capacity_unit']).to be_a Integer
    end
  end

  describe 'bind' do
    it 'maintains a binding for the service instance' do
      name = node.provision(plan, credentials, version)['name']

      node.bind(name, {})

      expect(node.bindings).to have_key name
    end

    it 'maintains a secret for the binding' do
      allow(SecureRandom).to receive(:uuid).and_return('service-id', 'large-string', 'some-secret')
      name = node.provision(plan, credentials, version)['name']

      node.bind(name, {})
      expect(node.bindings[name]).to be_a Hash

      binding = node.bindings[name]
      expect(binding).to have_key 'secret'
      expect(binding['secret']).to eq 'some-secret'
    end

    it 'maintains the same data for multiple bindings to a single instance' do
      allow(SecureRandom).to receive(:uuid).and_return('service-id', 'large-string', 'some-secret', 'some-new-secret')

      name = node.provision(plan, credentials, version)['name']
      node.bind(name, {})
      node.bind(name, {})

      binding = node.bindings[name]
      expect(binding).to have_key 'secret'
      expect(binding['secret']).to eq 'some-secret'
    end

    it "returns its host and port, along with the binding's credentials" do
      allow(SecureRandom).to receive(:uuid).and_return('some-secret')
      allow(VCAP).to receive(:grab_ephemeral_port).and_return(1234)

      name = node.provision(plan, credentials, version)['name']
      expected_hash = {
        'host' => '127.0.0.1',
        'port' => 1234,
        'login' => 'binding',
        'secret' => 'some-secret'
      }

      expect(node.bind(name)).to eq expected_hash
    end
  end

end
