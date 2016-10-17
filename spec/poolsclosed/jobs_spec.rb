# rubocop:disable Metrics/LineLength
require 'spec_helper'
require 'pry-byebug'
describe PoolsClosed::Jobs do
  it 'returns when status is not running' do
    jobs = PoolsClosed::Jobs.new(@cnf)
    jobs.stub(:rundeck_call) do |_a, _b, _c|
      ['', '<MyDoc><executions><execution status="succeeded" id="1234"></execution></executions></MyDoc>']
    end
    expect(jobs.create_machine('mybox')).to eq('succeeded')
  end

  it 'does not return until status is succeeded' do
    jobs = PoolsClosed::Jobs.new(@cnf)
    counter = 0
    jobs.stub(:rundeck_call) do |meth, _url, _pay|
      if meth == :post
        ['', '<MyDoc><executions><execution status="running" id="1234"></execution></executions></MyDoc>']
      elsif counter < 5
        counter += 1
        ['', '<MyDoc><executions><execution status="running" id="1234"></execution></executions></MyDoc>']
      else
        ['', '<MyDoc><executions><execution status="succeeded" id="1234"></execution></executions></MyDoc>']
      end
    end
    jobs.create_machine('mybox')
    expect(counter).to eq 5
  end
end
