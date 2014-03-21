require 'spec_helper'

describe InstanceManager do
  let(:opts) do
    {
      logger: Logger.new(STDOUT),
      ip_route: ip_route,
      external_url: external_url,
      port: port
    }
  end

  let(:ip_route) { '127.0.0.1' }
  let(:external_url) { 'external_url.com' }
  let(:port) { 1234 }

  describe 'provision' do
    let(:instance_manager) { InstanceManager.new(opts) }
    it 'creates and stores a new instance id' do
      expect(instance_manager.instances).to be_empty

      instance_manager.provision
      expect(instance_manager.instances).to_not be_empty
    end


    it 'returns the instance id' do
      result = instance_manager.provision
      expect(result).to eq({ 'name' => instance_manager.instances.keys.first })
    end

    it 'maintains a large random number associated with the service instance' do
      allow(SecureRandom).to receive(:uuid).and_return('service-instance-id', 'some-large-string')

      expect(instance_manager.instances).to be_empty
      result = instance_manager.provision
      name = result['name']
      expect(instance_manager.instances[name]).to eq 'some-large-string'
    end
  end

  describe 'bind' do
    let(:instance_manager) { InstanceManager.new(opts) }

    it 'maintains a binding for the service instance' do
      name = instance_manager.provision['name']

      instance_manager.bind(name)

      expect(instance_manager.bindings).to have_key name
    end

    it 'maintains a secret for the binding' do
      allow(SecureRandom).to receive(:uuid).and_return('service-id', 'large-string', 'some-secret')
      name = instance_manager.provision['name']

      instance_manager.bind(name)
      expect(instance_manager.bindings[name]).to be_a Hash

      binding = instance_manager.bindings[name]
      expect(binding).to have_key 'secret'
      expect(binding['secret']).to eq 'some-secret'
    end

    it 'maintains the same data for multiple bindings to a single instance' do
      allow(SecureRandom).to receive(:uuid).and_return('service-id', 'large-string', 'some-secret', 'some-new-secret')

      name = instance_manager.provision['name']
      instance_manager.bind(name)
      instance_manager.bind(name)

      binding = instance_manager.bindings[name]
      expect(binding).to have_key 'secret'
      expect(binding['secret']).to eq 'some-secret'
    end

    it "returns its public url and binding's credentials" do
      allow(SecureRandom).to receive(:uuid).and_return('some-name','some-secret')

      name = instance_manager.provision['name']
      expected_hash = {
        'host' => ip_route,
        'port' => port,
        'login' => 'binding',
        'secret' => 'some-secret',
        'url' => "#{external_url}/#{name}"
      }

      expect(instance_manager.bind(name)).to eq expected_hash
    end
  end
end
