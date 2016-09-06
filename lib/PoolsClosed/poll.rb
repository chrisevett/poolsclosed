require 'celluloid'

module PoolsClosed
  class Poller 
    
    def initialize(cnf, machines)
      @cnf = cnf
      @machines = machines 
      Systemd::Journal.print(INFO, 'poll starting')
      @thread = Thread.new { pool_check }
      sleep 1
    end
    
    def pool_check
      loop do
        if @machines.quarantines_count < @cnf['quarantine_limit']
          if @machines.pool_count < @cnf['pool_size']
            @machines.add
          end
        else
          @machines.error('Quarantine count is over the limit')
        end
        sleep 5
      end
    end
  end
end
