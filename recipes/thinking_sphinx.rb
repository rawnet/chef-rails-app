
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

    # Create thinking sphinx init script
    template "/etc/init.d/#{app_name}_#{environment}_thinking_sphinx" do
      source "thinking_sphinx_init.sh.erb"
      owner "root"
      group "root"
      mode 00755
      variables({
                  "environment_root" => environment_root,
                  "environment"      => environment,
                  "rails_user"       => rails_user
                })
    end
    
    # thinking sphinx should run at boot
    service "#{app_name}_#{environment}_thinking_sphinx" do
      supports :status => true, :restart => true, :reload => true
      action :enable
    end

  end
end
