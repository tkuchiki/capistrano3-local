namespace :load do
  task :defaults do
    set :resque_log, -> { File.join(current_path, "log", "resque.log") }
    set :resque_pid, -> { File.join(current_path, "tmp", "pids", "resque.pid") }
    set :resque_config_path, -> { File.join(current_path, "config", "resque.yml") }
    set :resque_roles, -> { :app }
    set :resque_options, -> { "" }
  end
end

namespace :resque do
  desc "Start Resque"
  task :start do
    on roles(fetch(:resque_roles)) do
      within current_path do
        if test("[ -e #{fetch(:resque_pid)} ] && kill -0 #{get_resque_pid}")
          info "resque is running..."
        else
          with rails_env: fetch(:rails_env) do
            execute :bundle, "exec resque work", "-c", fetch(:resque_config_path), fetch(:resque_options), ">>", fetch(:resque_log)
          end
        end
      end
    end
  end

  desc "Stop Resque; use this when graceful_term(.resque)"
  task :stop do
    on roles(fetch(:resque_roles)) do
      within current_path do
        if test("[ -e #{fetch(:resque_pid)} ]")
          if test("kill -0 #{get_resque_pid}")
            info "stopping resque..."
            execute :kill, "-s QUIT", get_resque_pid
            execute :rm, fetch(:resque_pid)
          else
            info "cleaning up dead resque pid..."
            execute :rm, fetch(:resque_pid)
          end
        else
          info "resque is not running..."
        end
      end
    end
  end

  desc "Restart Resque(TERM); use this when graceful_term(.resque)"
  task :restart do
    on roles(fetch(:resque_roles)) do
      within current_path do
        info "resque restarting..."
        execute :kill, "-s TERM", get_resque_pid
        execute :rm, fetch(:resque_pid)
        with rails_env: fetch(:rails_env) do
          execute :bundle, "exec resque work", "-c", fetch(:resque_config_path), fetch(:resque_options), ">>", fetch(:resque_log)
        end
      end
    end
  end

  desc "Lists known workers"
  task :list do
    on roles(fetch(:resque_roles)) do
      within current_path do
        info "workers..."
        execute :bundle, "exec resque list"
      end
    end
  end
end

def get_resque_pid
  "`cat #{fetch(:resque_pid)}`"
end
