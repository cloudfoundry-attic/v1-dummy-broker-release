require 'spec_helper'

describe Dummy::Node do
  subject(:node) { Dummy::Node.new(opts) }

  let(:logger) { double('logger') }
  let(:opts) do
    {
      logger: logger
    }
  end
  let(:instance_manager) { double(InstanceManager) }
  let(:bindings_server) { double(BindingsApiServer, start!: nil) }

  before do
    stub_super
    allow(VCAP).to receive(:grab_ephemeral_port).and_return(1234)
    allow(InstanceManager).to receive(:new).and_return(instance_manager)
    allow(BindingsApiServer).to receive(:new).and_return(bindings_server)
  end

  describe 'initialize' do
    before do
      Dummy::Node.new(opts)
    end

    it 'passes an ephemeral port to the instance manager and api server' do
      expect(InstanceManager).to have_received(:new).with(opts.merge(logger: logger, port: 1234))
      expect(BindingsApiServer).to have_received(:new).with(instance_manager, opts.merge(logger: logger, port: 1234))
    end

    it 'starts the api server' do
      expect(bindings_server).to have_received(:start!)
    end
  end

  describe 'provision' do
    it 'delegates to the instance_manager' do
      allow(instance_manager).to receive(:provision)
      node.provision('free')
      expect(instance_manager).to have_received(:provision)
    end
  end

  describe 'bind' do
    it 'delegates to the instance_manager' do
      allow(instance_manager).to receive(:bind)
      node.bind('my-instance')
      expect(instance_manager).to have_received(:bind).with('my-instance')
    end
  end


  describe 'unbind' do
    it 'delegates to the instance manager' do
      credentials = {
        'host' => "",
        'port' => 8080,
        'login' => "",
        'secret' => "",
        'url' => ""
      }
      allow(instance_manager).to receive(:unbind)
      node.unbind(credentials)
      expect(instance_manager).to have_received(:unbind).with(credentials)
    end
  end

  describe '#service_name' do
    it 'returns the name of the service' do
      expect(node.service_name).to eql('Dummy')
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

def stub_super
  VCAP::Services::Base::Node.class_eval do
    def initialize(*args)
      @logger = args.first[:logger]
    end
  end
end
