require 'poolsclosed'
require 'yaml'
require 'mock_redis'
require 'rspec'

# putting our fake config here for now. Theres probably a better way to do this 
$cnf = {'rundeck_url' => 'http://fake.rundeckinstance.com:4440/',
         'create_job_uuid' => 'f0eb6497-c5a9-4a35-98f7-eb88d068c606',
         'delete_job_uuid' => '23f07c7f-4d52-4016-b092-c4126fda3691',
         'api_token' => 'fake-api-token',
         'environment' => 'development',
         'sinatra_port' => 42069,
         'pool_size' => 10,
         'quarantine_limit' => 2 }


# do some rspec config

RSpec.configure do |config|
  # config.
end
