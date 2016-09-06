module PoolsClosed
   
  require 'redis'

  class Machines
  
    QTINE    = 'poolsclosed_quarantines'
    AVAIL    = 'poolsclosed_availmachines'
    RLSD     = 'poolsclosed_releasedmachines'
    ERR      = 'poolsclosed_lasterror'

    def initialize(cnf)
      @cnf = cnf
      @redis = Redis.new(host: 'localhost', port: 6379)
      @jobs =  PoolsClosed::Jobs.new(cnf)
    end
  
    def quarantine_count
      @redis.smembers(QTINE).count
    end 

    def add
      t = Time.now
      name = "pool#{t.month}#{t.day}#{Faker::Lorem.characters(7)}"
      if(!@jobs.create_machine(name))
        @redis.sadd(QTINE, name)
      else
        @redis.sadd(AVAIL, name)
      end
    end

    def yield 
      # we will return nil if the cache is empty which i think
      # its ok to let the client handle 
      name = @redis.spop(AVAIL)
      if (name)
        @redis.sadd(RLSD, name)
        @redis.spop(AVAIL)
      end
    end 

    def delete(box_name) 
      if(!@jobs.delete_machine(box_name))
        @redis.sadd(QTINE, box_name) 
      end
    end

    def pool_count
      @redis.smembers(AVAIL).count
    end

    def error(msg="error")
      @redis.set(ERR,msg)
    end 

    def last_error
      @redis.get(ERR) 
    end

  end
end
