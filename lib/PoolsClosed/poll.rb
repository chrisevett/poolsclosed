require 'celluloid'

module PoolsClosed
  # starts a thread which will poll redis for an instance count
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
        if @machines.quarantine_count < @cnf['quarantine_limit']
          @machines.add if @machines.pool_count < @cnf['pool_size']
        else
          @machines.error('Quarantine count is over the limit')
        end
        sleep 5
      end
    end
  end
end
