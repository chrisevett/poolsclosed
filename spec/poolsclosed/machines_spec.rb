require 'spec_helper'
require 'pry-byebug'
require 'mock_redis'

describe PoolsClosed::Machines do
  def machines
    @machines ||= PoolsClosed::Machines.new($cnf)
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

  context 'add' do
    it 'adds a machine to redis on success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:create_machine).and_return('succeeded')
      machines.add
      result = @redis_instance.spop('poolsclosed_availmachines')
      expect(result).to include('pool')
    end

    it 'adds a quarantine to redis on not success' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:create_machine).and_return('failure')

      machines.add

      quarantine_result = @redis_instance.spop('poolsclosed_quarantines')
      expect(quarantine_result).to include('pool')

      pool_result = @redis_instance.spop('poolsclosed_availmachines')
      expect(pool_result).to be_nil
    end
  end

  context 'delete' do
    it 'adds a quarantine on failure' do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('failure')
      machines.delete('pool1234')
      quarantine_result = @redis_instance.spop('poolsclosed_quarantines')
      expect(quarantine_result).to include('pool')
    end

    it "doesn't add a quarantine on success" do
      allow_any_instance_of(PoolsClosed::Jobs).to receive(:delete_machine).and_return('succeeded')
      machines.delete('pool1235')
      quarantine_result = @redis_instance.spop('poolsclosed_quarantines')
      expect(quarantine_result).to be_nil
    end
  end

  context 'yield' do
    it 'returns a value that exists in redis' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool1236')
      result = machines.yield
      expect(result).to eq('pool1236')
    end

    it 'adds a yielded machine to released' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool1237')
      machines.yield
      result = @redis_instance.spop('poolsclosed_releasedmachines')
      expect(result).to eq('pool1237')
    end

    it 'removes a yielded machine from avail' do
      @redis_instance.sadd('poolsclosed_availmachines', 'pool1238')
      machines.yield
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

  context 'last_error' do
    it 'returns the last error from redis' do
      @redis_instance.set('poolsclosed_lasterror', 'YIKES!')
      expect(machines.last_error).to eq('YIKES!')
      @redis_instance.del('poolsclosed_lasterror')
    end
  end

  context 'error' do
    it 'adds an error to redis' do
      machines.error('BARF!!')
      result = @redis_instance.get('poolsclosed_lasterror')
      expect(result).to eq('BARF!!')
      @redis_instance.del('poolsclosed_lasterror')
    end
  end
end
