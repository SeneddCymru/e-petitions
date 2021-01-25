# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Rails.application.load_tasks

task(:default).clear_prerequisites

task default: %i[
  bundle:audit brakeman:check
  spec jasmine:ci cucumber
]

task :load_schema_if_empty do
  unless Site.table_exists?
    Rake::Task["db:schema:load"].invoke
  end
end

Rake::Task["db:migrate"].enhance(%w[load_schema_if_empty])
