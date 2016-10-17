# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe 'Poller' do
  before(:each) do
    @machines = PoolsClosed::Machines.new(@cnf)
    @poller = PoolsClosed::Poller.new(@cnf, @machines)
    allow_any_instance_of(PoolsClosed::Machines).to receive(:add)
    allow_any_instance_of(PoolsClosed::Machines).to receive(:error)
  end

  context 'initialize' do
    it 'starts a new thread to poll' do
      allow_any_instance_of(PoolsClosed::Machines).to receive(:quarantine_count).and_return(0)
      allow_any_instance_of(PoolsClosed::Machines).to receive(:pool_count).and_return(0)
      expect(@poller.thread).to_not be_nil
    end
  end

  # in our test config the pool size is 10 and the quarantine limit 2
  context 'pool_check' do
    it 'adds a machine when quarantines <= limit and pool_count < limit ' do
      allow_any_instance_of(PoolsClosed::Machines).to receive(:quarantine_count).and_return(0)
      allow_any_instance_of(PoolsClosed::Machines).to receive(:pool_count).and_return(5)

      @poller.pool_check

      expect(@machines).to have_received(:add)
    end

    it 'adds an error when quarantines > limit' do
      allow_any_instance_of(PoolsClosed::Machines).to receive(:quarantine_count).and_return(1000)
      allow_any_instance_of(PoolsClosed::Machines).to receive(:pool_count).and_return(0)
      @poller.pool_check

      expect(@machines).to have_received(:error)
    end

    it 'does not add a machine when pool count >= limit' do
      allow_any_instance_of(PoolsClosed::Machines).to receive(:quarantine_count).and_return(0)
      allow_any_instance_of(PoolsClosed::Machines).to receive(:pool_count).and_return(0)

      @poller.pool_check
    end
  end
end
