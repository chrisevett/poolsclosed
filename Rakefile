require 'rubocop/rake_task'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

desc 'run rubocop'
RuboCop::RakeTask.new(:rubocop)

# i did this because it had trouble loading gems using the actual task
desc 'rspec'
task(:spec) { ruby '-S rspec' }

desc 'default'
task default: [:rubocop, :spec]
