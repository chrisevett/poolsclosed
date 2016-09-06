module PoolsClosed
  class Runner 
  
    def initialize(cnf,machines)
      begin
        @cnf = YAML.load_file(File.join(File.dirname(__FILE__),'../../config.yml'))
      rescue Exception => ex
        Systemd::Journal.print(ERR, 'Failed to load config.yml')
        exit -1
      end
      
       machines = Machines.new(cnf)
       poll = Poller.new(cnf, machines)
    end
  end
end 
