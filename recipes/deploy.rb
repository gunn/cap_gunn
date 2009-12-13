namespace :deploy do
  desc "Deploy app"
  task :default do
    git_push
    migrations
  end
  
  desc "Git push to the online repo"
  task :git_push, :except => { :no_release => true } do
    system "cd #{local_current_path} && git push"
  end
  
  desc "Step one - scp the repo and shared dir online, set up structure there."
  task :setup, :except => { :no_release => true } do
    run "mkdir -p #{base_path}"
    system "git clone --bare #{local_current_path} #{local_repository}"
    system "cd #{local_repository} && git gc;"
    system "scp -r -P #{port} #{local_repository} #{local_shared_path} #{user}@#{application}:#{base_path}/"
    run "git clone #{repository} #{current_path}"
    
    reload_nginx
    restart
  end
  
  desc "Attempt safe reload of nginx config"
  task :reload_nginx, :except => { :no_release => true } do
    run "#{try_sudo} /etc/init.d/nginx reload"
  end
 
  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}; git submodule init; git submodule update"
  end
 
  desc "Deploy and run migrations"
  task :migrations, :except => { :no_release => true } do
    update_code
    migrate
    restart
  end
 
  desc "Run pending migrations on already deployed code"
  task :migrate, :except => { :no_release => true } do
    run "cd #{current_path}; rake RAILS_ENV=production db:migrate"
  end
 
  namespace :rollback do
    desc "Rollback"
    task :default do
      code
    end
    
    desc "Rollback a single commit."
    task :code, :except => { :no_release => true } do
      set :branch, "HEAD^"
      default
    end
  end
  
  
  # override default tasks to make capistrano happy
  desc "Kick Passenger"
  task :start do
    run "touch #{current_path}/tmp/restart.txt"
  end
 
  desc "Kick Passenger"
  task :restart do
    stop
    start
  end
 
  desc "Kick Passenger"
  task :stop do
  end
end