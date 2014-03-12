require 'spec_helper'

describe 'V1 Dummy Broker', components: [:nats, :ccng, :broker] do

  let(:service_name) { 'v1-test' }
  let(:plan_name) { 'free' }

  before do
    #login_to_ccng_as('12345', 'user@example.com')
    #@login_info = {user_id: user_guid, email: email}
  end

  it 'populates CC with broker service and plan' do
    services = ccng_get('/v2/services')
    service  = services['resources'].first['entity']

    expect(service['label']).to eq('v1-test')

    plans = ccng_get(service['service_plans_url'])
    plan  = plans['resources'].first['entity']

    expect(plan['name']).to eq('free')
  end

  it 'provisions a service instance' do
    expect(ccng_get('/v2/service_instances')['resources']).to be_empty
    instance_guid = provision_service_instance('my_instance', service_name, plan_name)
    expect(instance_guid).to_not be_nil
    expect(ccng_get('/v2/service_instances')['resources']).not_to be_empty
  end

end
