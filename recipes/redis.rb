node_root = node['rails_app']
app_user = node_root['app_user']
admin_user = node_root['admin_user']

node_root['apps'].each do |name, app_config|
  app_root = File.join('/', 'home', app_user, 'apps', name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)
    environment_config = app_config['environment_config'][environment]
    config_dir = File.join(environment_root, 'shared', 'config')

    break unless environment_config['redis']

    template File.join('/', 'etc', 'init.d', "#{name}_#{environment}_redis") do
      source 'redis_init.sh.erb'
      owner admin_user
      group admin_user
      mode 00755
      variables(app_name: name, environment_root: environment_root, environment: environment, user: app_user)
    end

    service "#{name}_#{environment}_redis" do
      supports status: true, restart: true, reload: true
      action :enable
    end

    template File.join(config_dir, 'redis.conf') do
      source 'redis.conf.erb'
      owner app_user
      group app_user
      mode 00755
      variables(port: environment_config['redis']['port'], environment: environment, environment_root: environment_root, password: environment_config['redis']['password'])
      notifies :restart, "service[#{name}_#{environment}_redis]", :delayed
    end

    template File.join('/', 'etc', 'monit', 'conf.d', "#{name}_#{environment}_redis.conf") do
      source 'redis_monit.conf.erb'
      owner admin_user
      group admin_user
      mode 00644
      variables(app_name: name, environment_root: environment_root, port: environment_config['redis']['port'], environment: environment)
      notifies :restart, 'service[monit]', :delayed
    end

    template File.join(config_dir, 'redis.yml') do
      source 'redis.yml.erb'
      owner app_user
      group app_user
      mode 00755
      variables(environment: environment, config: environment_config['redis'])
    end
  end
end
