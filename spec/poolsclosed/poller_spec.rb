# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe 'Poller' do
  before(:each) do
    @machines = PoolsClosed::Machines.new(@cnf)
    @poller = PoolsClosed::Poller.new(@cnf, @machines)
    allow(@machines).to receive(:add!)
    allow(@machines).to receive(:error!)
    allow(@machines).to receive(:delete!)
    allow(@machines).to receive(:drain!)
  end

  context 'initialize' do
    it 'starts a new thread to poll' do
      allow(@machines).to receive(:quarantine_count).and_return(0)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:pending_deletions).and_return(0)
      
      expect(@poller.thread).to_not be_nil      
    end

    it 'starts in fill mode' do
      allow(@machines).to receive(:quarantine_count).and_return(0)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:pending_deletions).and_return(0)

      expect(@poller.mode).to be == 'fill'
    end
  end

  # in our test config the pool size is 10 and the quarantine limit 2
  context 'pool_check' do
    it 'adds a machine when quarantines <= limit and pool_count < limit ' do
      allow(@machines).to receive(:quarantine_count).and_return(0)
      allow(@machines).to receive(:pool_count).and_return(5)
      allow(@machines).to receive(:pending_deletions).and_return(0)

      @poller.pool_check

      expect(@machines).to have_received(:add!)
    end

    it 'adds an error when quarantines > limit ' do
      # TODO: fix this test to handle the deletion case
      allow(@machines).to receive(:quarantine_count).and_return(1000)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:pending_deletions).and_return(0)
      @poller.pool_check

      expect(@machines).to have_received(:error!)
    end

    it 'does not add a machine when pending deletions > limit' do
      allow(@machines).to receive(:pending_deletions).and_return(1000)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:quarantine_count).and_return(0)
      @poller.pool_check

      expect(@machines).to_not have_received(:add!)
    end

    it 'does not add a machine when pool count >= limit' do
      allow(@machines).to receive(:quarantine_count).and_return(0)
      allow(@machines).to receive(:pool_count).and_return(1000)
      allow(@machines).to receive(:pending_deletions).and_return(0)

      @poller.pool_check
      expect(@machines).to_not have_received(:add!)
    end

    it 'calls delete if there are pending deletions and we are below the quarantine limit' do
      allow(@machines).to receive(:quarantine_count).and_return(0)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:pending_deletions).and_return(5)

      @poller.pool_check
      expect(@machines).to have_received(:delete!)
    end

    it 'does not call delete if there are pending deletions and the quarantine count is too high' do
      allow(@machines).to receive(:quarantine_count).and_return(10_000)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:pending_deletions).and_return(5)

      @poller.pool_check
      expect(@machines).to_not have_received(:delete!)
    end

    it 'does not add a machine when mode == drain' do
      allow(@machines).to receive(:quarantine_count).and_return(0)
      allow(@machines).to receive(:pool_count).and_return(0)
      allow(@machines).to receive(:pending_deletions).and_return(0)
      @poller.mode = 'drain'

      @poller.pool_check
      expect(@machines).to_not have_received(:add!)
    end
  end

  context 'mode_set' do
    it 'should set mode to fill if fill is passed in' do
      @poller.mode_set!('fill')

      expect(@poller.mode).to be == 'fill'
    end

    it 'should set mode to drain and call machine.drain when drain is passed in' do
      @poller.mode_set!('drain')

      expect(@poller.mode).to be == 'drain'
      expect(@machines).to have_received(:drain!)
    end

    it 'should not update mode when given invalid parameter' do
      @poller.mode = 'fill'

      returnValue = @poller.mode_set!('help')

      expect(@poller.mode).to be == 'fill'
      expect(@machines).to_not have_received(:drain!)
      expect(returnValue).to be == 'Unexpected mode provided'
    end
  end
end
