# rubocop:disable Metrics/LineLength
require 'spec_helper'
require 'pry-byebug'
require 'mock_redis'

describe PoolsClosed::Machines do
  def machines
    @machines ||= PoolsClosed::Machines.new(@cnf)
  end

  # note, stubs in before(:all) get wiped out after the first time
  before(:each) do
    @redis_instance = MockRedis.new
    Redis.stub(:new).with(any_args).and_return(@redis_instance)
  end

  context 'initialize' do
    it 'creates instance of Jobs' do
      expect(machines.jobs).to_not be_nil
    end
  end

  context 'add!' do
    it 'adds a machine to redis on success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:create_machine).and_return('succeeded')
      machines.add!
      result = @redis_instance.spop('poolsclosed_availmachines')
      expect(result).to include('pool')
    end

    it 'adds a quarantine to redis on not success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:create_machine).and_return('failure')

      machines.add!

      quarantine_result = @redis_instance.spop('poolsclosed_quarantines')
      expect(quarantine_result).to include('pool')

      pool_result = @redis_instance.spop('poolsclosed_availmachines')
      expect(pool_result).to be_nil
    end
  end

  context 'queue_delete!' do
    it 'removes an entry from RLSD' do
      @redis_instance.sadd('poolsclosed_releasedmachines', 'mybox1010')

      machines.queue_delete!('mybox1010')

      rlsd_result = @redis_instance.spop('poolsclosed_releasedmachines')
      dltd_result = @redis_instance.spop('poolsclosed_deletepending')

      expect(dltd_result).to eq('mybox1010')
      expect(rlsd_result).to be_nil
    end

    it 'adds an entry to PDLT' do
    end
  end

  context 'delete!' do
    it 'adds a quarantine on failure' do
      # set up RLDS key
      @redis_instance.sadd('poolsclosed_releasedmachines', 'pool1234')
      @redis_instance.spop('poolsclosed_quarantines')
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('failure')
      machines.delete_helper('pool1234')
      quarantine_result = @redis_instance.spop('poolsclosed_quarantines')
      expect(quarantine_result).to include('pool')
    end

    it 'does not add an entry to DLTD on failure' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('failure')
      machines.delete_helper('pool1234')
      deleted_result = @redis_instance.spop('poolsclosed_deleted')
      expect(deleted_result).to be_nil
    end

    it 'adds an entry to DLTD on success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('succeeded')
      machines.delete_helper('pool12300')
      deleted_result = @redis_instance.spop('poolsclosed_deleted')
      expect(deleted_result).to include('pool')
    end

    it 'does not add a quarantine on success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('succeeded')
      machines.delete_helper('pool1235')
      quarantine_result = @redis_instance.spop('poolsclosed_quarantines')
      expect(quarantine_result).to be_nil
    end

    it 'removes an entry from PDLT on success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('succeeded')
      machines.delete_helper('pool12301')
      pendingdelete_result = @redis_instance.spop('poolsclosed_deletepending')
      expect(pendingdelete_result).to be_nil
    end

    it 'removes an entry from PDLT on failure' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('failure')
      machines.delete_helper('pool12301')
      pendingdelete_result = @redis_instance.spop('poolsclosed_deletepending')
      expect(pendingdelete_result).to be_nil
    end
  end

  context 'drain!' do
    it 'moves any machines in AVAIL to PDLT' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool001')
      @redis_instance.sadd('poolsclosed_availmachines', 'pool002')
      @redis_instance.sadd('poolsclosed_availmachines', 'pool003')

      machines.drain!

      avail_result = @redis_instance.spop('poolsclosed_availmachines')
      pdlt_result1 = @redis_instance.spop('poolsclosed_deletepending')
      pdlt_result2 = @redis_instance.spop('poolsclosed_deletepending')
      pdlt_result3 = @redis_instance.spop('poolsclosed_deletepending')

      expect(pdlt_result1).to eq('pool003')
      expect(pdlt_result2).to eq('pool002')
      expect(pdlt_result3).to eq('pool001')
      expect(avail_result).to be_nil
    end

    it 'should not blow up when AVAIL is empty' do
      machines.drain!

      avail_result = @redis_instance.spop('poolsclosed_availmachines')
      pdlt_result = @redis_instance.spop('poolsclosed_deletepending')

      expect(avail_result).to be_nil
      expect(pdlt_result).to be_nil
    end
  end

  context 'yield!' do
    it 'returns a value that exists in redis' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool1236')
      result = machines.yield!
      expect(result).to eq('pool1236')
    end

    it 'adds a yielded machine to released' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool1237')
      machines.yield!
      result = @redis_instance.spop('poolsclosed_releasedmachines')
      expect(result).to eq('pool1237')
    end

    it 'removes a yielded machine from avail' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool1238')
      machines.yield!
      @redis_instance.spop('poolsclosed_releasedmachines')
      result = @redis_instance.spop('poolsclosed_availmachines')

      expect(result).to be_nil
    end
  end

  context 'quarantine_count' do
    it 'returns the correct count from redis' do
      @redis_instance.sadd('poolsclosed_quarantines', 'pool1239')
      @redis_instance.sadd('poolsclosed_quarantines', 'pool1240')
      expect(machines.quarantine_count).to eq(2)
      @redis_instance.del('poolsclosed_quarantines')
    end
  end

  context 'pending_deletions' do
    it 'returns the correct count from redis' do
      @redis_instance.sadd('poolsclosed_deletepending', 'pool1250')
      @redis_instance.sadd('poolsclosed_deletepending', 'pool1251')
      expect(machines.pending_deletions).to eq(2)
      @redis_instance.del('poolsclosed_deletepending')
    end
  end

  context 'last_error' do
    it 'returns the last error from redis' do
      @redis_instance.set('poolsclosed_lasterror', 'YIKES!')
      expect(machines.last_error).to eq('YIKES!')
      @redis_instance.del('poolsclosed_lasterror')
    end
  end

  context 'error!' do
    it 'adds an error to redis' do
      machines.error!('BARF!!')
      result = @redis_instance.get('poolsclosed_lasterror')
      expect(result).to eq('BARF!!')
      @redis_instance.del('poolsclosed_lasterror')
    end
  end
end
