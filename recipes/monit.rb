
rails_apps = node["rails_app"]["apps"]
admin_user = node["rails_app"]["admin_user"]
rails_user = node["rails_app"]["rails_user"]

rails_apps.each_pair do |app_name, app_config|
  
  environments = app_config["environments"]
  
  app = data_bag_item('rails_apps', app_name)
  app_root = "/home/#{rails_user}/apps/#{app_name}"

  environments.each do |environment|
    
    node_config = {}
    environment, node_config = environment.first if environment.is_a?(Hash)
    config = app["environments"][environment]
    
    environment_root = app_root + "/#{environment}"

    template "/etc/monit/conf.d/#{app_name}_#{environment}.conf" do
      source "monit.conf.erb"
      owner admin_user
      group admin_user
      mode 00644
      variables({
                  "environment_root" => environment_root,
                  "app_name"         => app_name,
                  "environment"      => environment,
                  "config"           => config
                })

      notifies :restart, "service[monit]", :delayed
    end

  end
end
