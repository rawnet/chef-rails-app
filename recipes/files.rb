node_root = node['rails_app']
app_user = node_root['app_user']
admin_user = node_root['admin_user']

node_root['apps'].each do |name, app_config|
  app_root = File.join('/', 'home', app_user, 'apps', name)
  data_bag = data_bag_item('rails_app', name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)
    environment_config = app_config['environment_config'][environment]

    directory environment_root do
      owner app_user
      group app_user
      recursive true
    end

    # capistrano dirs
    %w[releases shared shared/assets shared/config shared/log
       shared/pids shared/system shared/tmp shared/sockets shared/db].each do |dir|
      directory File.join(environment_root, dir) do
        owner app_user
        group app_user
        recursive true
      end
    end

    config_dir = File.join(environment_root, 'shared', 'config')

    unless app_config['skip_database']
      database_config = environment_config['database'].merge(password: data_bag[environment]['database_password'])

      # database.yml
      template File.join(config_dir, 'database.yml') do
        source 'database.yml.erb'
        owner app_user
        group app_user
        mode 00755
        variables(app_name: name, environment: environment, database: database_config)
      end
    end

    # logrotate
    template File.join('/', 'etc', 'logrotate.d', "#{name}_#{environment}") do
      source 'logrotate.conf.erb'
      owner admin_user
      group admin_user
      mode 00644
      variables(environment_root: environment_root)
    end
  end
end
