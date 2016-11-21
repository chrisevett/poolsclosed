require 'celluloid'

module PoolsClosed
  # starts a thread which will poll redis for an instance count
  class Poller
    attr_reader :thread

    def initialize(cnf, machines)
      @cnf = cnf
      @machines = machines
      @mode = 'fill'
      puts('poll starting')
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
      @machines.add! if should_add?
      @machines.delete! if should_delete?
      @machines.error!('Quarantine count is over the limit') unless healthy?
    end

    def should_add?
      (@machines.pending_deletions < @cnf['quarantine_limit']) &&
        healthy? &&
        (@machines.pool_count < @cnf['pool_size']) &&
        @mode == 'fill'
    end

    def should_delete?
      (@machines.pending_deletions > 0) &&
        healthy? ||
        @mode == 'drain'
    end

    def healthy?
      @machines.quarantine_count < @cnf['quarantine_limit']
    end

    def mode!(mode)
      if mode == 'fill'
        @mode = mode
      elsif mode == 'drain'
        @mode = mode
        @machines.drain!
      else
        'Unexpected mode provided'
      end
    end
  end
end
