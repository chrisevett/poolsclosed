# poolsclosed
module PoolsClosed
  # this class is invoked by the file in bin/ and kicks off the poll
  class Runner
    def initialize(cnf, machines)
      begin
        @cnf = YAML.load_file(File.join(File.dirname(__FILE__),
                                        '../../config.yml'))
      rescue StandardError
        Systemd::Journal.print(ERR, 'Failed to load config.yml')
        exit(-1)
      end

      machines = Machines.new(cnf)
      Poller.new(cnf, machines)
    end
  end
end
