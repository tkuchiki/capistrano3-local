@dir = "/app"

cpu_cores = `getconf _NPROCESSORS_ONLN`.chomp.to_i
worker_processes  cpu_cores
working_directory "/app/current/"

listen 8080
#listen "#{@dir}/shared/tmp/sockets/unicorn.sock", :backlog => 1
timeout 60

pid "#{@dir}/shared/tmp/pids/unicorn.pid"

stderr_path "#{@dir}/shared/log/unicorn.stderr.log"
stdout_path "#{@dir}/shared/log/unicorn.stdout.log"

preload_app true
