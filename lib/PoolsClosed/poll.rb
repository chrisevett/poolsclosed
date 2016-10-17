require 'celluloid'

module PoolsClosed
  # starts a thread which will poll redis for an instance count
  class Poller
    attr_reader :thread

    def initialize(cnf, machines)
      @cnf = cnf
      @machines = machines
      Systemd::Journal.print(INFO, 'poll starting')
      @thread = Thread.new { pool_loop }
      sleep 1
    end

    # added this so I could test better
    def pool_loop
      loop do
        pool_check
        sleep 5
      end
    end

    def pool_check
      if @machines.quarantine_count < @cnf['quarantine_limit']
        @machines.add if @machines.pool_count < @cnf['pool_size']
      else
        @machines.error('Quarantine count is over the limit')
      end
    end
  end
end
