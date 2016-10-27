[![Build Status Master](https://travis-ci.org/chrisevett/poolsclosed.svg?branch=master)](https://travis-ci.org/chef/chef)
[![Join the chat at https://gitter.im/poolsclosed/Lobby](https://badges.gitter.im/poolsclosed/Lobby.svg)](https://gitter.im/poolsclosed/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
# poolsclosed
Simple sinatra app that manages a pool of machines via rundeck

![](http://i.imgur.com/H4hb6dG.jpg)

## Usage

### Installing

#### Using With Docker-Compose
Running poolsclosed in a Docker container is probably the easiest way to get started:
```
# clone the repo
# edit config file as needed
vim config.yml
# docker-compose up 
docker-compose up --build
```

#### Running locally without docker
Clone the repo, install redis, and then  
```ruby -Ilib bin/poolsclosed``` 

### Configuration
In config.yml:   
```   
rundeck_url: base url of the rundeck instance you are consuming.      
create_job_uuid: rundeck job ID that creates a vm. The job must take one arg: machineName
delete_job_uuid: rundeck job ID that deletes a vm. The job must take one arg: machineName 
api_token: rundeck api token
environment: sinatra environment parameter. This isn't used currently, so just leave the default as 'development'
sinatra_port: port you want the sinatra instance to listen on 
pool_size: number of VM's you want to have active at once
quarantine_limit: number of failures tolerated before no more vm's are created
redis_endpoint: redis machine name. use the default port 6379 
```    
      
### Endpoints

**Claim a machine from the pool**  
GET /machine  
Success Response:  
200  
{machineRelease: machineName}    

**Delete a machine that has previously been claimed**  
DELETE /machine  
params:   
machineName = [string]  
200  
{machineDelete: nil}  

**Get the last error code from the service**  
GET /status  
200  
{status: lasterror }  

**Get a list of quarantines**  
GET /quarantines  
200  
{quarantines: {machine1,machine2} }  

### Quarantines
If there is a failure creating or deleting a machine, poolsclosed will list it as a "quarantine". If the maximum number of quarantines is reached then it will stop creating new machines.   

## Using With Docker-Compose
Running poolsclosed in a Docker container is probably the easiest way to get started:
```
# clone the repo
# edit config file as needed
vim config.yml
# docker-compose up 
docker-compose up --build
```

### Note about resetting failed instances 
Until I can add more features, clearing out quarantines will require the user to manually go into redis and delete the records. I think this is acceptable at the moment because removing 'quarantined' machines will also take lots of manual intervention.   

## Use cases

I wrote this originally so I could do TDD with chef cookbooks on windows environments using our on-prem vsphere instance. I needed to be able to provision a new machine and join it to the domain before testing which could take as long as 15 minutes in some circumstances. This service will ensure that we have a set of pre-built machines so our provisioning step takes 0 seconds.   

## Contributing
Pull requests welcome. If there is a feature you want to see open an issue.  

## Todo 
Make a test-kitchen plugin to call this service.  
Publish to docker hub  
Add alerting for quarantines via email or a chat plugin.    

## License
MIT  
 
