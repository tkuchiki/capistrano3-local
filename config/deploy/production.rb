set :stage, :production

app_hosts = %w{}

role :app, app_hosts

app_hosts.each do |host|
  server host, user: "app", ssh_options: {
    user: 'user_name', # overrides user setting above
    keys: ["#{fetch(:key_dir)}/deploy_id_rsa"],
    forward_agent: false,
    auth_methods: %w(publickey)
  }
end
