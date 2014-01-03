node_root = node['rails_app']
app_user = node_root['app_user']
admin_user = node_root['admin_user']

node_root['apps'].each do |name, app_config|
  app_root = File.join('/', 'home', app_user, 'apps', name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)
    environment_config = app_config['environment_config'][environment]

    next unless environment_config['resque']

    template File.join('/', 'etc', 'init.d', "#{name}_#{environment}_resque") do
      source 'resque_init.sh.erb'
      owner admin_user
      group admin_user
      mode 00755
      variables(app_name: name, environment_root: environment_root, environment: environment, user: app_user, resque_workers: environment_config['resque']['worker_processes'])
    end

    service "#{name}_#{environment}_resque" do
      supports status: true, restart: true, reload: true
      action :enable
    end

    template File.join('/', 'etc', 'monit', 'conf.d', "#{name}_#{environment}_resque.conf") do
      source 'resque_monit.conf.erb'
      owner admin_user
      group admin_user
      mode 00644
      variables({
        :app_name         => name,
        :environment_root => environment_root,
        :environment      => environment,
        :resque_workers   => environment_config['resque']['worker_processes'],
        :max_memory       => (environment_config['resque']['max_memory']) || 300
      })

      notifies :restart, 'service[monit]', :delayed
    end
  end
end
