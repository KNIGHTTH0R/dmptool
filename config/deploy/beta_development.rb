role :web, 'dmp2-dev.cdlib.org'
role :app, 'dmp2-dev.cdlib.org'
role :db,  'dmp2-dev.cdlib.org', :primary => true # This is where Rails migrations will run

set :deploy_to, "/dmp2/apps/dmp2-beta/"
set :unicorn_pid, "/dmp2/apps/dmp2-beta/shared/tmp/unicorn.dmp2.pid"

after 'deploy', 'deploy:migrate'
before 'deploy:restart', 'deploy:symlink_shared'
after 'deploy:restart', 'unicorn:restart'