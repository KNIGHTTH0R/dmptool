role :web, 'uc3-dmp2-prd.cdlib.org'
role :app, 'uc3-dmp2-prd.cdlib.org'
role :db,  'uc3-dmp2-prd.cdlib.org', :primary => true # This is where Rails migrations will run

set :deploy_to, "/dmp2/apps/dmp2/"
set :unicorn_pid, "/dmp2/apps/dmp2/shared/tmp/unicorn.dmp2.pid"
set :rails_env, "production"

before 'bundle:install', 'deploy:prepare_bundle_config'

after 'deploy', 'deploy:migrate'
after 'deploy:finalize_update', 'deploy:symlink_shared'
load  'deploy/assets'
after 'deploy:restart', 'unicorn:restart'
