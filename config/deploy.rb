$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
require 'capistrano/ext/multistage'
require 'bundler/capistrano'

set :application, 'dc21app'
set :stages, %w(qa staging production)
set :default_stage, "qa"
set :rpms, %w{openssl openssl-devel curl-devel httpd-devel apr-devel apr-util-devel zlib zlib-devel libxml2 libxml2-devel libxslt libxslt-devel libffi mod_ssl mod_xsendfile postgresql84-server postgresql84 postgresql84-devel}
set :shared_children, shared_children + %w(log_archive)
set :shell, '/bin/bash'
set :rvm_ruby_string, 'ruby-1.9.2-p290@dc21app'
set :rvm_type, :user

# Deploy using copy for now
set :scm, 'git'
set :repository, 'ssh://git.intersect.org.au/git/dc21'
set :deploy_via, :copy
set :copy_exclude, [".git/*"]

set(:user) { "#{defined?(user) ? user : 'devel'}" }
set(:group) { "#{defined?(group) ? group : user}" }
set(:user_home) { "/home/#{user}" }
set(:deploy_to) { "#{user_home}/#{application}" }
set(:data_dir) { "#{defined?(data_dir) ? data_dir : '/data/dc21-samples'}" }

default_run_options[:pty] = true

namespace :server_setup do
  task :rpm_install, :roles => :app do
    run "#{try_sudo} yum install -y #{rpms.join(' ')}"
  end
  namespace :filesystem do
    task :dir_perms, :roles => :app do
      run "[[ -d #{data_dir} ]] || #{try_sudo} mkdir -p #{data_dir}"
      run "#{try_sudo} chown -R #{user}.#{group} #{data_dir}"
      run "[[ -d #{deploy_to} ]] || #{try_sudo} mkdir #{deploy_to}"
      run "#{try_sudo} chown -R #{user}.#{group} #{deploy_to}"
      run "#{try_sudo} chmod 0711 #{user_home}"
    end
  end
  namespace :rvm do
    task :trust_rvmrc do
      run "rvm rvmrc trust #{release_path}"
    end
  end
  task :gem_install, :roles => :app do
    run "gem install bundler passenger"
  end
  task :passenger, :roles => :app do
    run "passenger-install-apache2-module -a"
  end
  namespace :config do
    task :apache do
      src = "#{release_path}/config/httpd/#{stage}_rails_#{application}.conf"
      dest = "/etc/httpd/conf.d/rails_#{application}.conf"
      run "cmp -s #{src} #{dest} > /dev/null; [ $? -ne 0 ] && #{try_sudo} cp #{src} #{dest} && #{try_sudo} /sbin/service httpd graceful; /bin/true"
    end
  end
  namespace :logging do
    task :rotation, :roles => :app do
      src = "#{release_path}/config/#{application}.logrotate"
      dest = "/etc/logrotate.d/#{application}"
      run "cmp -s #{src} #{dest} > /dev/null; [ $? -ne 0 ] && #{try_sudo} cp #{src} #{dest}; /bin/true"
      src = "#{release_path}/config/httpd/httpd.logrotate"
      dest = "/etc/logrotate.d/httpd"
      run "cmp -s #{src} #{dest} > /dev/null; [ $? -ne 0 ] && #{try_sudo} cp #{src} #{dest}; /bin/true"
    end
  end
end

before 'deploy:setup' do
  server_setup.rpm_install
  server_setup.rvm.trust
  server_setup.gem_install
  server_setup.passenger
end
after 'deploy:setup' do
  server_setup.filesystem.dir_perms
end
after 'deploy:update' do
  server_setup.logging.rotation
  server_setup.config.apache
  deploy.restart
end

namespace :deploy do

  # Passenger specifics: restart by touching the restart.txt file
  task :start, :roles => :app, :except => {:no_release => true} do
    restart
  end
  task :stop do
    ;
  end
  task :restart, :roles => :app, :except => {:no_release => true} do
    run "touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  # Remote bundle install
  task :rebundle do
    run "cd #{current_path} && bundle install"
    restart
  end

  task :bundle_update do
    run "cd #{current_path} && bundle update"
    restart
  end

  # Load the schema
  desc "Load the schema into the database (WARNING: destructive!)"
  task :schema_load, :roles => :db do
    run("cd #{current_path} && rake db:schema:load", :env => {'RAILS_ENV' => "#{stage}"})
  end

  # Run the sample data populator
  desc "Run the test data populator script to load test data into the db (WARNING: destructive!)"
  task :populate, :roles => :db do
    run("cd #{current_path} && rake db:populate", :env => {'RAILS_ENV' => "#{stage}"})
  end

  # Seed the db
  desc "Run the seeds script to load seed data into the db (WARNING: destructive!)"
  task :seed, :roles => :db do
    run("cd #{current_path} && rake db:seed", :env => {'RAILS_ENV' => "#{stage}"})
  end

  desc "Full redepoyment, it runs deploy:update and deploy:refresh_db"
  task :full_redeploy do
    update
    rebundle
    refresh_db
  end

  # Helper task which re-creates the database
  task :refresh_db, :roles => :db do
    schema_load
    seed
    populate
  end

end

after 'deploy:update_code' do
  generate_database_yml
  run "cd #{release_path}; RAILS_ENV=#{stage} rake assets:precompile"
end

desc "After updating code we need to populate a new database.yml"
task :generate_database_yml, :roles => :app do
  require "yaml"
  set :production_database_password, proc { Capistrano::CLI.password_prompt("Database password: ") }

  buffer = YAML::load_file('config/database.yml')
  # get rid of unneeded configurations
  buffer.delete('test')
  buffer.delete('development')
  buffer.delete('cucumber')
  buffer.delete('spec')

  # Populate production password
  buffer['production']['password'] = production_database_password

  put YAML::dump(buffer), "#{release_path}/config/database.yml", :mode => 0664
end
