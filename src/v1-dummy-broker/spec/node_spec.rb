require 'spec_helper'

describe Dummy::Node do

  subject(:node) { described_class.new(opts) }

  let(:opts) do
    {
      logger: Logger.new(STDOUT)
    }
  end

  let(:plan) { 'free' }
  let(:credentials) { nil }
  let(:version) { nil }

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

      expect(result).to eq({ 'name' => node.instances.first })
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

end
