# poolsclosed
module PoolsClosed
  require 'restclient'
  require 'nokogiri'

  # interacts with rundeck to kick off create and delete jobs
  class Jobs
    def initialize(cnf)
      @cnf = cnf
    end

    def create_machine(name)
      wait_for_rundeck(create_exec(name))
    end

    def delete_machine(name)
      wait_for_rundeck(delete_exec, name)
    end

    private

    def create_exec(name)
      url = ["#{@cnf['rundeck_url']}api/12/job/",
             "#{@cnf['create_job_uuid']}/executions"].join('')
      exec_id(url, name)
    end

    def delete_exec(name)
      url = ["#{@cnf['rundeck_url']}api/12/job/",
             "#{@cnf['delete_job_uuid']}/executions"].join('')
      exec_id(url, name)
    end

    def exec_id(url, name)
      response = rundeck_call(:post,
                              url,
                              argString: "-machineName #{name}")

      Nokogiri::XML(response[1]).xpath('//execution/@id')[0].value
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

    # rubocop:disable MethodLength, LineLength
    def rundeck_call(method, url, payload)
      RestClient::Request.new(method: method,
                              url: url,
                              payload: payload,
                              headers: { content_type: :json,
                                         'X-Rundeck-Auth-Token' =>
                                         @cnf['api_token'] }).execute do |rsp, _request, _result|
        case rsp.code
        when 200
          [:success, rsp.to_str]
        else
          raise "Error, received response #{rsp.to_str}"
        end
      end
    end
    # rubocop:enable MethodLength, LineLength
  end
end
