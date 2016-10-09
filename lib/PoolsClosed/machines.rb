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

    def initialize(cnf)
      @cnf = cnf
      #@redis = Redis.new(host: 'localhost', port: 6379)
      @redis = Redis.new(host: 'compose_redis', port: 6379)
      @jobs =  PoolsClosed::Jobs.new(cnf)
    end

    def quarantine_count
      @redis.smembers(QTINE).count
    end

    def add
      name = generate_machinename
      if @jobs.create_machine(name) != 'succeeded'
        @redis.sadd(QTINE, name)
      else
        @redis.sadd(AVAIL, name)
      end
    end

    def yield
      # we will return nil if the cache is empty which i think
      # its ok to let the client handle
      name = @redis.spop(AVAIL)
      return unless name

      @redis.sadd(RLSD, name)
      @redis.spop(AVAIL)
    end

    def delete(box_name)
      return if @jobs.delete_machine(box_name) == 'succeeded'
      @redis.sadd(QTINE, box_name)
    end

    def pool_count
      @redis.smembers(AVAIL).count
    end

    def error(msg = 'error')
      @redis.set(ERR, msg)
    end

    def last_error
      @redis.get(ERR)
    end

    private

    def generate_machinename
      t = Time.now
      "pool#{t.month}#{t.day}#{Faker::Lorem.characters(7)}"
    end
  end
end
