begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ['--display-cop-names', '--no-color']
  end
rescue LoadError
  puts 'rubocop is not available'
end

desc 'Run quality checks'
task test: [:spec, :style]

desc 'default'
task default: [:test]
