
rails_apps = data_bag('rails_apps')
admin_user = node["admin_user"]
rails_user = node["rails_app_user"]

rails_apps.each do |app_name|

  app = data_bag_item('rails_apps', app_name)
  app_root = "/home/#{rails_user}/apps/#{app_name}"

  app['environments'].each do |environment, config|
    environment_root = app_root + "/#{environment}"

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

    # Create database.yml
    template "#{environment_root}/shared/config/database.yml" do
      source "database.yml.erb"
      owner rails_user
      group rails_user
      mode 00755
      variables({
                  "app_name"    => app_name,
                  "environment" => environment,
                  "database"    => config['database']
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

    # Create Nginx config
    template "/etc/nginx/sites-available/#{app_name}_#{environment}.conf" do
      source "nginx.conf.erb"
      owner admin_user
      group admin_user
      mode 00644
      variables({
                  "environment_root" => environment_root,
                  "app_name"         => app_name,
                  "environment"      => environment,
                  "domains"          => config['domains']
                })
    end

    link "/etc/nginx/sites-enabled/#{app_name}_#{environment}.conf" do
      to "/etc/nginx/sites-available/#{app_name}_#{environment}.conf"
      notifies :reload, "service[nginx]", :delayed
    end

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