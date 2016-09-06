module PoolsClosed
  class Jobs

    def initialize(cnf)
      @cnf = cnf
    end

    def create_machine
      run_job('create')
    end

    def delete_machine
      run_job('delete')
    end 

  private 
   
   def run_job(task)
     case task
     when 'create'
       wait_for_rundeck(create_exec)
     when 'delete'
       wait_for_rundeck(delete_exec)
     else
       raise "error, bad request"
     end
   end 

   def create_exec
     url = ["#{@cnf['rundeck_url']}api/12/job/",
     "#{@cnf['create_job_uuid']}/executions"].join('')
     exec_id(url)
   end

   def delete_exec   
     url = ["#{@cnf['rundeck_url']}api/12/job/",
     "#{@cnf['delete_job_uuid']}/executions"].join('')
     exec_id(url)
   end 

   def exec_id(url)
      response = rundeck_call(:post,
                              url,
                              argString: "-machineName #{generate_machinename}")

      Nokogiri::XML(response[1]).doc.xpath('//execution/@id')[0].value
    end
 
    def wait_for_rundeck(execution_id)
      execution_status = 'running'
      url = "#{@cnf['rundeck_url']}api/1/execution/#{execution_id}"
      until execution_status != 'running'
        sleep 10
        response = rundeck_call(:get, url, nil)
        doc = Nokogiri::XML(response[1])
        execution_node = doc.xpath('//execution/@status')
        execution_status = execution_node[0].value
      end
      execution_status
    end

    def rundeck_call(method, url, payload)
      RestClient::Request.new(method: method,
                              url: url, payload: payload,
                              headers: { content_type: :json, 
                                         'X-Rundeck-Auth-Token' =>
                                          @cnf['api_token'] }
                             ).execute do |rsp, _request, _result|
        case rsp.code
        when 200
          [:success, rsp.to_str]
        else
          raise "Error, received response #{rsp.to_str}"
        end
      end
    end

  end
end
