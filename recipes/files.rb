
rails_apps = node["rails_app"]["apps"]
admin_user = node["rails_app"]["admin_user"]
rails_user = node["rails_app"]["rails_user"]

rails_apps.each_pair do |app_name, app_config|
  
  environments = app_config["environments"]
  
  app = data_bag_item('rails_apps', app_name)
  env = app[node.chef_environment]
  raise env.inspect
  app_root = "/home/#{rails_user}/apps/#{app_name}"

  environments.each do |environment|
    config = app["environments"][environment]
    environment_root = app_root + "/#{environment}"
    
    if !env.nil? && env["environments"] && env["environments"][environment]
      env_config = env["environments"][environment]
    else
      env_config = {}
    end

    # Create the environment directory
    directory environment_root do
      owner rails_user
      group rails_user
      recursive true
    end

    # Create the capistrano directories
    %w(releases shared shared/assets shared/config shared/log
     shared/pids shared/system shared/tmp shared/sockets shared/db shared/db/sphinx).each do |dir|
      directory "#{environment_root}/#{dir}" do
        owner rails_user
        group rails_user
        recursive true
      end
    end
    
    if env_config.has_key?("database")
      db_config = config['database'].merge(env_config['database'])
    else
      db_config = config['database']
    end

    # Create database.yml
    template "#{environment_root}/shared/config/database.yml" do
      source "database.yml.erb"
      owner rails_user
      group rails_user
      mode 00755
      variables({
                  "app_name"    => app_name,
                  "environment" => environment,
                  "database"    => db_config
                })
    end

    # Create unicorn config
    template "#{environment_root}/shared/config/unicorn.rb" do
      source "unicorn_config.rb.erb"
      owner rails_user
      group rails_user
      mode 00755
      variables({
                  "environment_root" => environment_root,
                  "unicorn_workers"  => config['unicorn_workers']
                })
    end

    # Create unicorn init script
    template "/etc/init.d/#{app_name}_#{environment}_unicorn" do
      source "unicorn_init.sh.erb"
      owner "root"
      group "root"
      mode 00755
      variables({
                  "environment_root" => environment_root,
                  "environment"      => environment,
                  "rails_user"       => rails_user
                })
    end
    
    # unicorns should run at boot
    service "#{app_name}_#{environment}_unicorn" do
      supports :status => true, :restart => true, :reload => true
      action :enable
    end

    # Create Nginx config
    domains = config['domains']
    domains += config['local_domains'] unless config['local_domains'].nil?
    template "/etc/nginx/sites-available/#{app_name}_#{environment}.conf" do
      source "nginx.conf.erb"
      owner admin_user
      group admin_user
      mode 00644
      variables({
                  "environment_root" => environment_root,
                  "app_name"         => app_name,
                  "environment"      => environment,
                  "domains"          => domains,
                  "default_vhost"    => config['default_vhost'] || false
                })
    end

    link "/etc/nginx/sites-enabled/#{app_name}_#{environment}.conf" do
      to "/etc/nginx/sites-available/#{app_name}_#{environment}.conf"
      notifies :reload, "service[nginx]", :delayed
    end
    
    config['local_domains'].each do |local|
      hostsfile_entry '127.0.0.1' do
        hostname  local
        action    :append
      end
    end unless config['local_domains'].nil?

    template "/etc/monit/conf.d/#{app_name}_#{environment}.conf" do
      source "monit.conf.erb"
      owner admin_user
      group admin_user
      mode 00644
      variables({
                  "environment_root" => environment_root,
                  "app_name"         => app_name,
                  "environment"      => environment,
                  "unicorn_workers"  => config['unicorn_workers']
                })

      notifies :restart, "service[monit]", :delayed
    end

  end

end