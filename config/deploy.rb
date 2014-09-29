# config valid only for Capistrano 3.1
lock '3.2.1'

set :config_dir, File.expand_path(File.dirname(__FILE__))
set :deploy_dir, File.join(fetch(:config_dir), "deploy")
set :cap_root,   File.dirname(fetch(:config_dir))

set :key_dir,    File.join(fetch(:cap_root), "keys")
set :application, 'app'
#set :repo_url, 'git@example.com:me/my_repo.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/app'

# Default value for :scm is :git
#set :scm, :rsync
set :scm, :copy

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs,   %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

# capistrano-scm-copy
set :exclude_dir, ["vendor", ".git"]

# capistrano/rbenv
## default
# set :rbenv_roles, :all # default value
# set :rbenv_type, :user # or :system, depends on your rbenv setup
# set :rbenv_prefix,   "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
# set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_path, "/usr/local/rbenv"
set :rbenv_ruby, "2.1.3"

# capistrano3/unicorn settings
## default
# set :unicorn_pid, -> { File.join(current_path, "tmp", "pids", "unicorn.pid") }
# set :unicorn_config_path, -> { File.join(current_path, "config", "unicorn", "#{fetch(:rails_env)}.rb") }
# set :unicorn_roles, -> { :app }
# set :unicorn_options, -> { "" }
# set :unicorn_rack_env, -> { fetch(:rails_env) == "development" ? "development" : "deployment" }
set :unicorn_config_path, -> { File.join(current_path, "config", "unicorn.rb") }
set :unicorn_restart_sleep_time, 5

# capistrano/bundle
## default
# set :bundle_roles, :all
# set :bundle_servers, -> { release_roles(fetch(:bundle_roles)) }
# set :bundle_binstubs, -> { shared_path.join('bin') }
# set :bundle_without, %w{development test}.join(' ')
# set :bundle_flags, '--deployment --quiet'
# set :bundle_env_variables, {}
set :bundle_gemfile, -> { release_path.join('Gemfile') }   # default: nil
set :bundle_path, -> { shared_path.join('vendor/bundle') }
cpu_cores = `getconf _NPROCESSORS_ONLN`.chomp.to_i
set :bundle_jobs, cpu_cores

# resque.rake
## default
# set :resque_log, -> { File.join(current_path, "log", "resque.log") }
# set :resque_pid, -> { File.join(current_path, "tmp", "pids", "resque.pid") }
# set :resque_config_path, -> { File.join(current_path, "config", "resque.yml") }
# set :resque_roles, -> { :app }
# set :resque_options, -> { "" }

set :upload_bin_files, ["unicorn_start.sh", "unicorn_stop.sh", "unicorn_restart.sh", "resque_start.sh", "resque_stop.sh", "resque_restart.sh"]
set :config_files,     ["unicorn", "resque"]

set :shared_bin,    -> { File.join(shared_path, "bin") }
set :shared_config, -> { File.join(shared_path, "config") }

set :unicorn_user,  "app"
set :unicorn_group, "app"
set :unicorn_start_script,   -> { File.join(fetch(:shared_bin), "unicorn_start.sh") }
set :unicorn_stop_script,    -> { File.join(fetch(:shared_bin), "unicorn_stop.sh") }
set :unicorn_restart_script, -> { File.join(fetch(:shared_bin), "unicorn_restart.sh") }

set :resque_user,  "app"
set :resque_group, "app"
set :resque_start_script,   -> { File.join(fetch(:shared_bin), "resque_start.sh") }
set :resque_stop_script,    -> { File.join(fetch(:shared_bin), "resque_stop.sh") }
set :resque_restart_script, -> { File.join(fetch(:shared_bin), "resque_restart.sh") }

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke "unicorn:legacy_restart"
    end
  end

  after :publishing, :restart

  desc 'Upload files'
  task :upload do
    on roles(:app) do |host|
      fetch(:upload_bin_files).each do |file|
        template    = "#{fetch(:deploy_dir)}/templates/#{file}.erb"
        upload_from = StringIO.new(ERB.new(File.read(template)).result(binding))
        upload_to   = File.join(fetch(:shared_bin), File.basename(template, ".erb"))
        upload! upload_from, upload_to
      end

      fetch(:config_files).each do |file|
        execute :mkdir, "-p", fetch(:shared_config)
        template    = "#{fetch(:deploy_dir)}/templates/config/#{file}.erb"
        upload_from = StringIO.new(ERB.new(File.read(template)).result(binding))
        upload_to   = File.join(fetch(:shared_config), File.basename(template, ".erb"))
        upload! upload_from, upload_to
      end
    end
  end

  before :starting, :upload
  after :finishing, 'deploy:cleanup'
  
end
