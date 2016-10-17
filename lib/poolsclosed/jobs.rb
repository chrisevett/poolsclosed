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
      parse_id(response)
    end

    def parse_id(xml)
      Nokogiri::XML(xml[1]).xpath('//execution/@id')[0].value
    end

    def wait_for_rundeck(execution_id)
      execution_status = 'running'
      url = "#{@cnf['rundeck_url']}api/1/execution/#{execution_id}"
      until execution_status != 'running'
        sleep 10
        response = rundeck_call(:get, url, nil)
        execution_status = parse_status(response)
      end
      execution_status
    end

    def parse_status(xml)
      Nokogiri::XML(xml[1]).xpath('//execution/@status')[0].value
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
          puts "error contacting rundeck. Received response #{rsp.to_str}"
        end
      end
    rescue StandardError => e
      puts 'error hitting rundeck'
      puts e.message
      return -1
    end
    # rubocop:enable MethodLength, LineLength
  end
end
