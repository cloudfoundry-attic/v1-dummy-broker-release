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
  let(:instance_manager) { InstanceManager.new(opts) }

  describe 'provision' do
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

    it 'maintains the number of bindings for a service instance' do
      name = instance_manager.provision['name']

      expect(instance_manager.bindings).not_to have_key name

      instance_manager.bind(name)

      expect(instance_manager.bindings).to have_key name
      expect(instance_manager.bindings[name]).to have_key 'num_bindings'
      expect(instance_manager.bindings[name]['num_bindings']).to eq 1

      instance_manager.bind(name)
      expect(instance_manager.bindings).to have_key name
      expect(instance_manager.bindings[name]).to have_key 'num_bindings'
      expect(instance_manager.bindings[name]['num_bindings']).to eq 2
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
        'url' => "#{external_url}/#{name}",
        'name' => name
      }

      expect(instance_manager.bind(name)).to eq expected_hash
    end
  end

  describe 'unbind' do
    it 'removes the binding for the service instance and returns true' do
      name = instance_manager.provision['name']

      credentials = instance_manager.bind(name)

      response = instance_manager.unbind(credentials)

      expect(instance_manager.bindings).not_to have_key name
      expect(response).to be_true
    end

    context 'when service instance does not exist' do
      it 'return false' do
        credentials = {'name' => 'name'}
        response = instance_manager.unbind(credentials)
        expect(response).to be_false
      end
    end

    context 'when a service instance has many bindings' do
      it 'one less binding after the call to unbind' do
        name = instance_manager.provision['name']

        instance_manager.bind(name)
        credentials = instance_manager.bind(name)

        response = instance_manager.unbind(credentials)
        expect(instance_manager.bindings).to have_key name
        expect(instance_manager.bindings[name]).to have_key 'num_bindings'
        expect(instance_manager.bindings[name]['num_bindings']).to eq 1
        expect(response).to be_true
      end
    end
  end

  describe 'unprovision' do
    let!(:service_id) { instance_manager.provision['name'] }

    it 'removes the service instance id' do
      expect(instance_manager.instances[service_id]).to_not be_nil

      instance_manager.unprovision(service_id)
      expect(instance_manager.instances[service_id]).to be_nil
    end

    it 'returns true' do
      expect(instance_manager.unprovision(service_id)).to be_true
    end

    context 'when the service instance does not exist' do
      it 'returns true' do
        expect(instance_manager.unprovision('does not exist')).to be_true
      end
    end

    context 'when bindings for the instance exist' do
      before do
        instance_manager.bind(service_id)
      end

      it 'returns false' do
        expect(instance_manager.unprovision(service_id)).to be_false
      end
    end
  end
end
