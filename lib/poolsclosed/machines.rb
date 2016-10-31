# poolsclosed
module PoolsClosed
  require 'redis'
  require 'faker'

  # consumes our redis instance and instantiates the jobs class
  class Machines
    QTINE    = 'poolsclosed_quarantines'.freeze
    AVAIL    = 'poolsclosed_availmachines'.freeze
    RLSD     = 'poolsclosed_releasedmachines'.freeze
    ERR      = 'poolsclosed_lasterror'.freeze
    PDLT     = 'poolsclosed_deletepending'.freeze
    DLTD     = 'poolsclosed_deleted'.freeze

    attr_reader :jobs

    def initialize(cnf)
      @cnf = cnf
      @redis = Redis.new(host: cnf['redis_endpoint'], port: 6379)
      @jobs =  PoolsClosed::Jobs.new(cnf)
    end

    def quarantine_count
      @redis.smembers(QTINE).count
    end

    def pending_deletions
      @redis.smembers(PDLT).count
    end

    def add!
      name = generate_machinename
      if @jobs.create_machine(name) != 'succeeded'
        @redis.sadd(QTINE, name)
      else
        @redis.sadd(AVAIL, name)
      end
    end

    def yield!
      # we will return nil if the cache is empty which i think
      # its ok to let the client handle
      name = @redis.spop(AVAIL)
      return unless name
      @redis.sadd(RLSD, name)
      name
    end

    def queue_delete!(box_name)
      @redis.srem(RLSD, box_name)
      @redis.sadd(PDLT, box_name)
    end

    def delete!
      machine_name = @redis.spop(PDLT)
      delete_helper(machine_name) if machine_name
    end

    def pool_count
      @redis.smembers(AVAIL).count
    end

    def error!(msg = 'error')
      @redis.set(ERR, msg)
    end

    def last_error
      @redis.get(ERR)
    end

    def generate_machinename
      t = Time.now
      "pool#{t.month}#{t.day}#{Faker::Lorem.characters(7)}"
    end

    def delete_helper(box_name)
      if @jobs.delete_machine(box_name) == 'succeeded'
        @redis.sadd(DLTD, box_name)
      else
        @redis.sadd(QTINE, box_name)
      end
    end
  end
end
