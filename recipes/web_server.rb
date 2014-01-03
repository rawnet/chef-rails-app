node_root = node['rails_app']
app_user = node_root['app_user']
admin_user = node_root['admin_user']

node_root['apps'].each do |name, app_config|
  app_root = File.join('/', 'home', app_user, 'apps', name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)
    environment_config = app_config['environment_config'][environment]

    # TODO: add support for thin, puma etc
    if app_config['app_server'] == 'unicorn'
      # unicorn.rb
      template File.join(environment_root, 'shared', 'config', 'unicorn.rb') do
        source 'unicorn_config.rb.erb'
        owner app_user
        group app_user
        mode 00755
        variables(environment_root: environment_root, unicorn: environment_config['unicorn'])

        if File.directory? File.join(environment_root, 'current')
          notifies :restart, "service[#{name}_#{environment}_unicorn]", :delayed
        end
      end

      # unicorn init script
      template File.join('/', 'etc', 'init.d', "#{name}_#{environment}_unicorn") do
        source 'unicorn_init.sh.erb'
        owner 'root'
        group 'root'
        mode 00755
        variables({
          :environment_root          => environment_root,
          :environment               => environment,
          :unicorn_bin               => environment_config['unicorn']['bin'] || 'unicorn', # support rails 2 apps that use unicorn_rails
          :app_user                  => app_user,
          :environment_variable_name => environment_config['environment_variable_name'] || 'RAILS_ENV' # support non rails apps that use RACK_ENV
        })
      end

      # start unicorn on boot
      service "#{name}_#{environment}_unicorn" do
        supports :status => true, :restart => true, :reload => true
        action :enable
      end

      # unicorn monit
      template File.join('/', 'etc', 'monit', 'conf.d', "#{name}_#{environment}_unicorn") do
        source 'unicorn_monit.conf.erb'
        owner admin_user
        group admin_user
        mode 00644

        variables({
          :environment_root => environment_root,
          :app_name         => name,
          :environment      => environment,
          :config           => environment_config
        })

        notifies :restart, 'service[monit]', :delayed
      end
    end

    # nginx
    domains = environment_config['domains'] + (environment_config['local_domains'] || [])
    nginx_conf_dir = File.join('/', 'etc', 'nginx')

    template File.join(nginx_conf_dir, 'sites-available', "#{name}_#{environment}.conf") do
      source 'nginx.conf.erb'
      owner admin_user
      group admin_user
      mode 00644

      variables({
        :environment_root => environment_root,
        :app_name         => name,
        :environment      => environment,
        :domains          => domains,
        :config           => environment_config['nginx'] || {},
        :http_basic_auth  => environment_config['http_basic_auth'],
        :load_balancer    => environment_config['behind_load_balancer']
      })

      notifies :reload, 'service[nginx]', :delayed
    end

    link File.join(nginx_conf_dir, 'sites-enabled', "#{name}_#{environment}.conf") do
      to File.join(nginx_conf_dir, 'sites-available', "#{name}_#{environment}.conf")
      notifies :reload, 'service[nginx]', :delayed
    end

    if environment_config['http_basic_auth']
      template File.join(environment_root, 'shared', 'config', 'http_basic_auth.conf') do
        source 'http_basic_auth.conf.erb'
        owner app_user
        group app_user
        mode 00644
        variables(username: environment_config['http_basic_auth']['username'], password: environment_config['http_basic_auth']['password'])
        notifies :reload, 'service[nginx]', :delayed
      end
    end

    if environment_config['local_domains']
      environment_config['local_domains'].each do |local|
        hostsfile_entry '127.0.0.1' do
          hostname local
          action :append
        end
      end
    end
  end
end
