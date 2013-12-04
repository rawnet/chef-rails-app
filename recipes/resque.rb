rails_apps = node['rails_app']['apps']
admin_user = node['rails_app']['admin_user']
rails_user = node['rails_app']['rails_user']

rails_apps.each_pair do |app_name, app_config|
  app_root = File.join('/', 'home', rails_user, 'apps', app_name)
  app_data_bag = data_bag_item('rails_apps', app_name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)
    environment_config = app_data_bag['environments'][environment]

    break unless environment_config['resque']

    template File.join('/', 'etc', 'init.d', "#{app_name}_#{environment}_resque") do
      source 'resque_init.sh.erb'
      owner admin_user
      group admin_user
      mode 00755
      variables(app_name: app_name, environment_root: environment_root, environment: environment, user: rails_user, resque_workers: environment_config['resque']['worker_processes'])
    end

    service "#{app_name}_#{environment}_resque" do
      supports status: true, restart: true, reload: true
      action :enable
    end

    template File.join('/', 'etc', 'monit', 'conf.d', "#{app_name}_#{environment}_resque.conf") do
      source 'resque_monit.conf.erb'
      owner admin_user
      group admin_user
      mode 00644
      variables(app_name: app_name, environment_root: environment_root, environment: environment, resque_workers: environment_config['resque']['worker_processes'])
      notifies :restart, 'service[monit]', :delayed
    end
  end
end
