include_recipe "rails-app::files"

rails_apps = node['rails_app']['apps']
admin_user = node['rails_app']['admin_user']
rails_user = node['rails_app']['rails_user']

rails_apps.each_pair do |app_name, app_config|
  app_root = File.join('/', 'home', rails_user, 'apps', app_name)
  app_data_bag = data_bag_item('rails_apps', app_name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)
    config_dir = File.join(environment_root, 'shared', 'config')
    environment_config = app_data_bag['environments'][environment]

    break unless environment_config['redis']

    template File.join('/', 'etc', 'init.d', "#{app_name}_#{environment}_redis") do
      source 'redis_init.sh.erb'
      owner admin_user
      group admin_user
      mode 00755
      variables(app_name: app_name, environment_root: environment_root, environment: environment, user: rails_user)
    end

    service "#{app_name}_#{environment}_redis" do
      supports status: true, restart: true, reload: true
      action :enable
    end

    template File.join(config_dir, 'redis.conf') do
      source 'redis.conf.erb'
      owner rails_user
      group rails_user
      mode 00755
      variables(port: environment_config['redis']['port'], environment: environment, environment_root: environment_root, password: environment_config['redis']['password'])
      notifies :restart, "service[#{app_name}_#{environment}_redis]", :delayed
    end

    template File.join('/', 'etc', 'monit', 'conf.d', "#{app_name}_#{environment}_redis.conf") do
      source 'redis_monit.conf.erb'
      owner admin_user
      group admin_user
      mode 00644
      variables(app_name: app_name, environment_root: environment_root, port: environment_config['redis']['port'], environment: environment)
      notifies :restart, 'service[monit]', :delayed
    end

    template File.join(config_dir, 'redis.yml') do
      source 'redis.yml.erb'
      owner rails_user
      group rails_user
      mode 00755
      variables(environment: environment, config: environment_config['redis'])
    end
  end
end
