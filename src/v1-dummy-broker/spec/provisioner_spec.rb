require 'spec_helper'

describe Dummy::Provisioner do
  let(:provisioner) { Dummy::Provisioner.new(options) }
  let(:options)     { gateway.provisioner_config }
  let(:gateway)     { Dummy::Gateway.new.tap { |g| g.load_config } }

  # Travis is having problems with EventMachine, so we need to stub it out for these tests
  let(:conn)        { double('conn', on_connect: nil)}
  let(:fake_em)     { double('em', connect: conn, add_periodic_timer: nil, add_timer: nil) }

  before do
    @old_em = EventMachine
    EM = fake_em
    EventMachine = fake_em
  end

  after do
    EM = @old_em
    EventMachine = @old_em
  end

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
