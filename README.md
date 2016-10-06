# poolsclosed
Simple sinatra app that manages a pool of machines via rundeck

![](http://i.imgur.com/H4hb6dG.jpg)

## Usage

### Installing
Until I push this to rubygems, clone the repo, install redis, and then  
```ruby -Ilib bin/poolsclosed``` 

Once I push this to rubygems:  
```gem install poolsclosed```

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

## Using With Docker
Running poolsclosed in a Docker container is probably the easiest way to get started:
```
mkdir docker-poolsclosed
cd docker-poolsclosed
wget https://raw.githubusercontent.com/chrisevett/poolsclosed/master/Dockerfile
wget https://raw.githubusercontent.com/chrisevett/poolsclosed/master/config.yml
# edit config file as needed
vim config.yml
# build the image and give it a tag name, build takes about 5 minutes the first run
docker build . -t pools_open_yo
# run exposing the sinatra web port defined in config.yml
docker run -p 42069:42069 pools_open_yo
```

### Note about resetting failed instances 
Until I can add more features, clearing out quarantines will require the user to manually go into redis and delete the records. I think this is acceptable at the moment because removing 'quarantined' machines will also take lots of manual intervention.   

## Use cases

I wrote this originally so I could do TDD with chef cookbooks on windows environments using our on-prem vsphere instance. I needed to be able to provision a new machine and join it to the domain before testing which could take as long as 15 minutes in some circumstances. This service will ensure that we have a set of pre-built machines so our provisioning step takes 0 seconds.   

## Contributing
Pull requests welcome. If there is a feature you want to see open an issue.  

## Todo 
Push this to rubygems  
Docker  
Make a test-kitchen plugin to call this service.  
Add alerting for quarantines via email or a chat plugin.    

## License
MIT  
 
